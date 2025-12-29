//
//  ICloudIntegrationTests.swift
//  The M'Cheyne Plan
//
//  Migrated to Swift Testing on 1/4/26.
//

import Foundation
import Testing

@Suite("iCloud Integration")
struct ICloudIntegrationTests {
    @Test("Complete user journey from V1 to iCloud")
    func testCompleteUserJourneyFromV1ToICloud() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        setupV1SchemaData(userDefaults: mockUserDefaults)

        _ = Plan(userDefaults: mockUserDefaults, store: mockStore)

        #expect(mockUserDefaults.bool(forKey: MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY))
        #expect(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        #expect(mockStore.object(forKey: "startDate") != nil)
        #expect(mockStore.data(forKey: "selections") != nil)

        if let migratedPassage = findPassage(
            withDescription: "Genesis 1", in: Plan(userDefaults: mockUserDefaults, store: mockStore)
        ) {
            #expect(mockStore.bool(forKey: migratedPassage.userDefaultsKeyV2))
        }

        let reloadedPlan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        guard let firstSelection = firstSelectionWithPassages(in: reloadedPlan) else {
            #expect(false, "Expected at least one non-leap selection with passages")
            return
        }
        let secondPassage = firstSelection.getPassages()[1]
        secondPassage.read()
        #expect(mockStore.bool(forKey: secondPassage.userDefaultsKeyV2))

        reloadedPlan.setSelfPaced(to: true)
        #expect(mockStore.bool(forKey: "selfPaced"))

        let newStartDate = Date(timeIntervalSince1970: 1_640_995_200)
        reloadedPlan.setStartDate(to: newStartDate)
        #expect((mockStore.object(forKey: "startDate") as? Date) == newStartDate)
    }

    @Test("Device sync scenario")
    func testDeviceSyncScenario() async throws {
        guard isICloudAvailable() else { return }

        let device1UserDefaults = MockUserDefaults()
        let device1Store = MockUbiquitousKeyValueStore()

        _ = Plan(userDefaults: device1UserDefaults, store: device1Store)
        let plan1 = Plan(userDefaults: device1UserDefaults, store: device1Store)
        guard let plan1Selection = firstSelectionWithPassages(in: plan1) else {
            #expect(false, "Expected at least one non-leap selection with passages")
            return
        }

        for i in 0..<3 {
            plan1Selection.getPassages()[i].read()
        }
        plan1.setSelfPaced(to: true)

        let device2UserDefaults = MockUserDefaults()
        device2UserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)

        let device2Store = MockUbiquitousKeyValueStore()
        device2Store.persistedDictionary = device1Store.persistedDictionary

        let plan2 = Plan(userDefaults: device2UserDefaults, store: device2Store)
        guard let plan2Selection = firstSelectionWithPassages(in: plan2) else {
            #expect(false, "Expected at least one non-leap selection with passages")
            return
        }

        #expect(plan2.isSelfPaced)
        #expect(plan2.startDate.timeIntervalSince1970 == plan1.startDate.timeIntervalSince1970)

        for i in 0..<3 {
            #expect(plan2Selection.getPassages()[i].completed)
        }
        #expect(plan2Selection.getPassages()[3].completed == false)
    }

    @Test("Conflict resolution scenario")
    func testConflictResolutionScenario() async throws {
        guard isICloudAvailable() else { return }

        let device1UserDefaults = MockUserDefaults()
        let device1Store = MockUbiquitousKeyValueStore()
        device1UserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)

        let device2UserDefaults = MockUserDefaults()
        let device2Store = MockUbiquitousKeyValueStore()
        device2UserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)

        let baseStartDate = Date(timeIntervalSince1970: 1_640_995_200)
        device1Store.set(baseStartDate, forKey: "startDate")
        device2Store.set(baseStartDate, forKey: "startDate")

        let plan1 = Plan(userDefaults: device1UserDefaults, store: device1Store)
        let plan2 = Plan(userDefaults: device2UserDefaults, store: device2Store)
        guard let plan1Selection = firstSelectionWithPassages(in: plan1),
            let plan2Selection = firstSelectionWithPassages(in: plan2)
        else {
            #expect(false, "Expected at least one non-leap selection with passages")
            return
        }

        plan1Selection.getPassages()[0].read()
        plan2Selection.getPassages()[1].read()

        device2Store.persistedDictionary = device1Store.persistedDictionary

        let notification = Notification(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: device2Store)
        plan2.testHandleICloudSync(notification: notification)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(plan2Selection.getPassages()[0].completed)
        #expect(plan2Selection.getPassages()[1].completed == false)
    }

    @Test("Offline to online transition")
    func testOfflineToOnlineTransition() async throws {
        guard isICloudAvailable() else { return }

        let offlineUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        _ = Plan(userDefaults: offlineUserDefaults, store: mockStore)
        let reloadedPlan = Plan(userDefaults: offlineUserDefaults, store: mockStore)
        guard let firstSelection = firstSelectionWithPassages(in: reloadedPlan) else {
            #expect(false, "Expected at least one non-leap selection with passages")
            return
        }

        for i in 0..<5 {
            firstSelection.getPassages()[i].read()
        }
        reloadedPlan.setSelfPaced(to: true)

        #expect(offlineUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        #expect(mockStore.bool(forKey: "selfPaced"))

        for i in 0..<5 {
            let passage = firstSelection.getPassages()[i]
            #expect(mockStore.bool(forKey: passage.userDefaultsKeyV2))
        }
    }

    @Test("Data integrity after multiple migrations")
    func testDataIntegrityAfterMultipleMigrations() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        setupV1SchemaData(userDefaults: mockUserDefaults)

        _ = Plan(userDefaults: mockUserDefaults, store: mockStore)

        #expect(mockUserDefaults.bool(forKey: MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY))
        #expect(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))

        if let migratedPassage = findPassage(
            withDescription: "Genesis 1", in: Plan(userDefaults: mockUserDefaults, store: mockStore)
        ) {
            #expect(mockStore.bool(forKey: migratedPassage.userDefaultsKeyV2))
            #expect(mockUserDefaults.bool(forKey: migratedPassage.userDefaultsKeyV2) == false)
        }

        #expect(mockStore.object(forKey: "startDate") != nil)
        #expect(mockStore.data(forKey: "selections") != nil)
    }
}

private func setupV1SchemaData(userDefaults: MockUserDefaults) {
    let completedKeys = ["Genesis 1", "Matthew 1", "Ezra 1", "Acts 1"]
    for key in completedKeys {
        userDefaults.set(true, forKey: key)
    }

    userDefaults.set(Date(timeIntervalSince1970: 1_640_995_200), forKey: "startDate")
    userDefaults.set(false, forKey: "selfPaced")
}

private func findPassage(withDescription description: String, in plan: Plan) -> Passage? {
    for selection in plan.selections {
        if let passage = selection.getPassages().first(where: { $0.description == description }) {
            return passage
        }
    }
    return nil
}

private func firstSelectionWithPassages(in plan: Plan) -> ReadingSelection? {
    return plan.selections.first(where: { !$0.isLeap && !$0.getPassages().isEmpty })
}
