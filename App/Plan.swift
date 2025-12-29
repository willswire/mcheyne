//
//  Plan.swift
//  The M'Cheyne Plan
//
//  Created by Will Walker on 12/29/25.
//

import Foundation
import Combine

let DAY_IN_SECONDS: Double = 86400

class Passage: Identifiable, ObservableObject {
    @Published var completed: Bool = false
    var description: String
    var id: Int
    var userDefaults: UserDefaults
    var store: NSUbiquitousKeyValueStore?
    var userDefaultsKeyV2: String
    
    init(_ reference: String = "None", id: Int, userDefaults: UserDefaults, store: NSUbiquitousKeyValueStore? = nil) {
        self.description = reference
        self.id = id
        self.userDefaults = userDefaults
        self.store = store
        self.userDefaultsKeyV2 = description + "+" + String(id)
        
        // Load completed status from appropriate storage
        if let store = store, userDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY) {
            self.completed = store.bool(forKey: userDefaultsKeyV2)
        } else {
            self.completed = userDefaults.bool(forKey: userDefaultsKeyV2)
        }
        save()
    }
    
    func hasRead() -> Bool {
        return self.completed
    }
    
    func read() {
        self.completed = true
        save()
    }
    
    func unread() {
        self.completed = false
        save()
    }
    
    func save() {
        if let store = store, userDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY) {
            store.set(completed, forKey: userDefaultsKeyV2)
            store.synchronize()
        } else {
            userDefaults.set(completed, forKey: userDefaultsKeyV2)
        }
        self.objectWillChange.send()
    }
    
    func localizedDescription() -> String {
        if let lastSpaceIndex = self.description.lastIndex(of: " ")  {
            let bookName = String(self.description[..<lastSpaceIndex]) // Extract book name by removing the chapter (e.g., "Genesis")
            let localizedBook = String(localized: String.LocalizationValue(bookName), table: "Books")
            let chapter = self.description[self.description.index(after: lastSpaceIndex)...] // Extract the passage numbers

            return "\(localizedBook) \(chapter)"
        }
        
        return String(localized: String.LocalizationValue(self.description)) // Fallback if no space is found
    }

}

class ReadingSelection: ObservableObject {
    private var passages: [Passage] = []
    var isLeap: Bool = false
    
    init(_ references: [String] = Array(repeating: "None", count: 4), userDefaults: UserDefaults = UserDefaults.standard, store: NSUbiquitousKeyValueStore? = nil) {
        for reference in references {
            self.passages.append(Passage(reference, id: passages.count, userDefaults: userDefaults, store: store))
        }
    }
    
    init(leapYearEntry: Bool = false) {
        self.isLeap = leapYearEntry
    }
    
    func isComplete() -> Bool {
        return self.passages.allSatisfy { $0.hasRead() }
    }
    
    func getPassages() -> [Passage] {
        return self.passages
    }
    
    subscript(_ index: Int) -> Passage {
        return passages[index]
    }
}

class Plan: ObservableObject {
    @Published var startDate: Date
    @Published var selections: [ReadingSelection]
    @Published var isSelfPaced: Bool
    var userDefaults: UserDefaults
    var store = NSUbiquitousKeyValueStore.default
    
    var indexForTodaysDate: Int {
        if (self.isSelfPaced) {
            if let index = self.selections.firstIndex(where: { !$0.isComplete() }) {
                return index
            } else {
                return 0
            }
        } else {
            return self.indexForDateFromStartDate(from: Date())
        }
    }
    
    init(userDefaults: UserDefaults = UserDefaults.standard, store: NSUbiquitousKeyValueStore = .default) {
        self.userDefaults = userDefaults
        self.store = store
        
        let isICloudAvailable = FileManager.default.ubiquityIdentityToken != nil
        if isICloudAvailable { store.synchronize() }
                
        if isICloudAvailable && userDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY) {
            if let startDate = store.object(forKey: "startDate") as? Date {
                self.startDate = startDate
            } else {
                self.startDate = Date()
                store.set(Date(), forKey: "startDate")
            }
            self.isSelfPaced = store.bool(forKey: "selfPaced")
            
            if let selectionsData = store.data(forKey: "selections"),
               let references = try? JSONDecoder().decode([[String]].self, from: selectionsData) {
                self.selections = references.map { ReadingSelection($0, userDefaults: userDefaults, store: store) }
            } else {
                self.selections = RAW_PLAN_DATA.map { ReadingSelection($0, userDefaults: userDefaults, store: store) }
            }
        } else {
            if let startDate = userDefaults.value(forKey: "startDate") as? Date {
                self.startDate = startDate
            } else {
                self.startDate = Date()
                userDefaults.setValue(Date(), forKey: "startDate")
            }
            self.isSelfPaced = userDefaults.bool(forKey: "selfPaced")
            self.selections = RAW_PLAN_DATA.map { ReadingSelection($0, userDefaults: userDefaults, store: nil) }
        }
        self.insertLeapYearEntry()
        migrateUserDefaultsToV2SchemaIfRequired()
        migrateUserDefaultsToICloudIfRequired()

        // Listen for iCloud sync updates
        if isICloudAvailable {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleICloudSync),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: store
            )
        }
    }
    
    private func migrateUserDefaultsToV2SchemaIfRequired() {
        // If we've already migrated then no need to do more work
        if userDefaults.bool(forKey: MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY) {
            return
        }
        
        // Get a snapshot of UserDefaults for easy lookup
        let userDefaultsSnapshot: Dictionary<String, Any> = userDefaults.dictionaryRepresentation()
        
        // Update the `completed` state of the in-memory `Passage` objects using the value from the
        // v1 schema. Also collect all of the `ReadingSelection` instance that have a second appearance
        // of a passage, e.g. "Matthew 1."
        var selectionsWithSecondAppearanceOfPassage: Array<ReadingSelection> = []
        for schemaV1Key in USER_DEFAULTS_SCHEMA_V1_KEYS {
            // Ensure this key is in our snapshot
            if(userDefaultsSnapshot.index(forKey: schemaV1Key) == nil) {
                continue
            }
            
            // Force unwrap works here because we made sure the key exists above
            let completedV1: Bool = userDefaultsSnapshot[schemaV1Key] as! Bool
            
            // Skip this v1 key if `completed` is false because the default value from `Passage` is false
            if(!completedV1) {
                continue
            }
            
            // Collect the `ReadingSelection` objects that contain the matching `Passage`
            // Also collect the `Passage` objects themselves so we don't need more loops
            var selectionsContainingPassage: Array<ReadingSelection> = []
            var passagesForV1Key: Array<Passage> = []
            for selection in selections {
                for currentPassage in selection.getPassages() {
                    if currentPassage.description == schemaV1Key {
                        selectionsContainingPassage.append(selection)
                        passagesForV1Key.append(currentPassage)
                        break
                    }
                }
            }
            
            // Mark the first instance of the passage read since we know
            // the v1 schema had this `Passage` marked as read
            if let firstPassage = passagesForV1Key.first {
                firstPassage.read()
            }
            
            // If there isn't a second ReadingSelection then keep on moving
            if selectionsContainingPassage.count != 2 {
                continue
            }
            
            // Mark the second instance of the passage read and store the *second*
            // selection for reconciliation after all Passages have been populated
            // with their v1 `completed` value in this loop
            if let secondPassage = passagesForV1Key.last {
                secondPassage.read()
            }
            if let secondSelection = selectionsContainingPassage.last {
                selectionsWithSecondAppearanceOfPassage.append(secondSelection)
            }
        }
        
        // The second appearance of a passage will always be marked read if the
        // first appearance is marked read. If the selection is not complete then
        // assume the user hasn't read it yet and mark all passages as unread.
        selectionsWithSecondAppearanceOfPassage.forEach({ selection in
            if !selection.isComplete() {
                selection.getPassages().forEach({$0.unread()})
            }
        })
        
        // Clear all the v1 schema entries
        USER_DEFAULTS_SCHEMA_V1_KEYS.forEach({userDefaults.removeObject(forKey: $0)})
        
        // Mark the migration as complete
        userDefaults.set(true, forKey: MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY)
    }
    
    private func migrateUserDefaultsToICloudIfRequired() {
        // Check if iCloud is available
        guard FileManager.default.ubiquityIdentityToken != nil else {
            print("iCloud is not available. Skipping migration.")
            return
        }

        // Check if migration has already been done
        guard !userDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY) else {
            print("Migration already completed. No action needed.")
            return
        }
        
        print("Migrating UserDefaults data to iCloud...")

        // Move basic values to iCloud
        if let startDate = userDefaults.object(forKey: "startDate") as? Date {
            store.set(startDate, forKey: "startDate")
        }
        store.set(userDefaults.bool(forKey: "selfPaced"), forKey: "selfPaced")
        
        // Migrate all passage completion states
        for selection in selections {
            for passage in selection.getPassages() {
                if userDefaults.bool(forKey: passage.userDefaultsKeyV2) {
                    store.set(true, forKey: passage.userDefaultsKeyV2)
                }
            }
        }
        
        // Serialize selections structure (this preserves the reading plan structure)
        let selectionsData = try? JSONEncoder().encode(selections.map { $0.getPassages().map { $0.description } })
        store.set(selectionsData, forKey: "selections")
        
        store.synchronize()

        // After migration, reload from iCloud to ensure in-memory state reflects new source of truth
        if let selectionsData = store.data(forKey: "selections"),
           let references = try? JSONDecoder().decode([[String]].self, from: selectionsData) {
            self.selections = references.map { ReadingSelection($0, userDefaults: userDefaults, store: store) }
        } else {
            self.selections = RAW_PLAN_DATA.map { ReadingSelection($0, userDefaults: userDefaults, store: store) }
        }
        if let startDate = store.object(forKey: "startDate") as? Date { self.startDate = startDate }
        self.isSelfPaced = store.bool(forKey: "selfPaced")

        // Clean up old UserDefaults data after successful migration
        userDefaults.removeObject(forKey: "startDate")
        userDefaults.removeObject(forKey: "selfPaced")
        
        // Clean up passage completion states from UserDefaults
        for selection in selections {
            for passage in selection.getPassages() {
                userDefaults.removeObject(forKey: passage.userDefaultsKeyV2)
            }
        }

        // Mark migration as complete
        userDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        userDefaults.synchronize()
        
        print("Migration completed successfully.")
    }
    
    @objc func handleICloudSync(notification: Notification) {
        DispatchQueue.main.async {
            self.startDate = self.store.object(forKey: "startDate") as? Date ?? Date()
            self.isSelfPaced = self.store.bool(forKey: "selfPaced")
            if let selectionsData = self.store.data(forKey: "selections"),
               let references = try? JSONDecoder().decode([[String]].self, from: selectionsData) {
                self.selections = references.map { ReadingSelection($0, userDefaults: self.userDefaults, store: self.store) }
            } else {
                self.selections = RAW_PLAN_DATA.map { ReadingSelection($0, userDefaults: self.userDefaults, store: self.store) }
            }

            print("iCloud sync updated values.")
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getSelection(at index: Int?) -> ReadingSelection {
        return selections[index ?? self.indexForTodaysDate]
    }
    
    func setStartDate(to date: Date) {
        self.startDate = date
        if (userDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)) {
            store.set(date, forKey: "startDate")
            store.synchronize()
        } else {
            userDefaults.setValue(date, forKey: "startDate")
        }
        self.objectWillChange.send()
    }
    
    func reset() {
        for item in self.selections {
            for passage in item.getPassages() {
                passage.unread()
            }
        }
        setStartDate(to: Date())
    }
    
    func setSelfPaced(to value: Bool) {
        self.isSelfPaced = value
        
        if (userDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)) {
            store.set(value, forKey: "selfPaced")
            store.synchronize()
        } else {
            userDefaults.set(value, forKey: "selfPaced")
        }
    
        self.objectWillChange.send()
    }
    
    func changeStartDate(to date: Date) {
        self.reset()
        self.setStartDate(to: date)
        for i in 0..<indexForTodaysDate {
            for passage in self.selections[i].getPassages() {
                passage.read()
            }
        }
    }
}

extension Plan {
    private func insertLeapYearEntry() {
        var containsFebruary29th = false
        var leapIndex = 0
        let calendar = Calendar.current

        for day in 0..<365 {
            if let futureDate = calendar.date(byAdding: .day, value: day, to: self.startDate) {
                let dayComponent = calendar.component(.day, from: futureDate)
                let monthComponent = calendar.component(.month, from: futureDate)

                if dayComponent == 29 && monthComponent == 2 {
                    containsFebruary29th = true
                    break
                }
            }
            leapIndex += 1
        }
        
        if containsFebruary29th {
            self.selections.insert(ReadingSelection(leapYearEntry: true), at: leapIndex)
        }
    }
    
    func isLeapYear(_ year: Int) -> Bool {
        return (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0)
    }
    
    func daysInYear(_ year: Int) -> Int {
        return isLeapYear(year) ? 366 : 365
    }
    
    func indexForDateFromStartDate(from date: Date) -> Int {
        let calendar = Calendar.current
        
        // Calculate the difference in days between the start date and the given date
        let dateComponents = calendar.dateComponents([.day], from: self.startDate, to: date)
        guard let dayDifference = dateComponents.day else { return 0 }
        
        // If the difference in days is negative, the given date is before the start date, return 0
        if dayDifference < 0 {
            return 0
        }
        
        // Adjust index based on the actual length of the plan to prevent overflow
        let adjustedIndex = dayDifference % selections.count
        
        return adjustedIndex
    }
}

// Copied from https://stackoverflow.com/a/42623106
extension Date {
    var dayOfYear: Int {
        return Calendar.current.ordinality(of: .day, in: .year, for: self)! - 1
    }
}
