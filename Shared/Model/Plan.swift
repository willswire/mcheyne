import Foundation

let DAY_IN_SECONDS: Double = 86400

class Passage: Identifiable, ObservableObject {
    @Published var completed: Bool = false
    var description: String
    var id: Int
    var userDefaults: UserDefaults
    var userDefaultsKeyV2: String
    
    init(_ reference: String = "None", id: Int, userDefaults: UserDefaults) {
        self.description = reference
        self.id = id
        self.userDefaults = userDefaults
        self.userDefaultsKeyV2 = description + "+" + String(id)
        self.completed = userDefaults.bool(forKey: userDefaultsKeyV2)
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
        userDefaults.set(completed, forKey: userDefaultsKeyV2)
        self.objectWillChange.send()
    }
}

class ReadingSelection: ObservableObject {
    private var passages: [Passage] = []
    
    init(_ references: [String] = Array(repeating: "None", count: 4), userDefaults: UserDefaults = UserDefaults.standard) {
        for reference in references {
            self.passages.append(Passage(reference, id: passages.count, userDefaults: userDefaults))
        }
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
    
    func indexForDateFromStartDate(from date: Date) -> Int {
        var indexForDate: Int = 0
        if (Calendar.current.component(.year, from: date) > Calendar.current.component(.year, from: self.startDate)) {
            indexForDate = date.dayOfYear - self.startDate.dayOfYear + 365
        } else {
            indexForDate = date.dayOfYear - self.startDate.dayOfYear
        }
        
        // Prevent an index overflow if it's been awhile since the app was opened
        if indexForDate >= 365 {
            indexForDate -= 365
        }
        
        // Prevent an index underflow if there's a weird date setting on the device
        if indexForDate <= 0 {
            indexForDate = 0
        }
        
        return indexForDate
    }
    
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
        if let startDate = userDefaults.value(forKey: "startDate") as? Date {
            self.startDate = startDate
        } else {
            self.startDate = Date()
            userDefaults.setValue(Date(), forKey: "startDate")
        }
        self.isSelfPaced = userDefaults.bool(forKey: "selfPaced")
        self.selections = RAW_PLAN_DATA.map { ReadingSelection($0, userDefaults: userDefaults) }
        migrateUserDefaultsToV2SchemaIfRequired()
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
    
    func getSelection(at index: Int?) -> ReadingSelection {
        return selections[index ?? self.indexForTodaysDate]
    }
    
    func setStartDate(to date: Date) {
        self.startDate = date
        userDefaults.setValue(date, forKey: "startDate")
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
        userDefaults.set(value, forKey: "selfPaced")
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

// Copied from https://stackoverflow.com/a/42623106
extension Date {
    var dayOfYear: Int {
        return Calendar.current.ordinality(of: .day, in: .year, for: self)! - 1
    }
}
