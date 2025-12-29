//
//  ICloudMigrationTests.swift
//  The M'Cheyne Plan
//
//  Migrated to Swift Testing on 1/4/26.
//

import Foundation
import Testing

@Suite("iCloud Migration")
struct ICloudMigrationTests {
    @Test("Migration with empty UserDefaults")
    func testICloudMigrationWithEmptyUserDefaults() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        _ = Plan(userDefaults: mockUserDefaults, store: mockStore)

        #expect(mockStore.object(forKey: "startDate") != nil)
        #expect(mockStore.bool(forKey: "selfPaced") == false)
        #expect(mockStore.data(forKey: "selections") != nil)
        #expect(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        #expect(mockStore.synchronizeCallCount > 0)
    }

    @Test("Migration with existing UserDefaults data")
    func testICloudMigrationWithExistingUserDefaultsData() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        let startDate = Date(timeIntervalSince1970: 1_640_995_200)
        mockUserDefaults.set(startDate, forKey: "startDate")
        mockUserDefaults.set(true, forKey: "selfPaced")
        let testPassageKey = "Genesis 1+0"
        mockUserDefaults.set(true, forKey: testPassageKey)

        _ = Plan(userDefaults: mockUserDefaults, store: mockStore)

        #expect((mockStore.object(forKey: "startDate") as? Date) == startDate)
        #expect(mockStore.bool(forKey: "selfPaced"))
        #expect(mockStore.bool(forKey: testPassageKey))
        #expect(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        #expect(mockUserDefaults.object(forKey: "startDate") == nil)
        #expect(mockUserDefaults.bool(forKey: "selfPaced") == false)
        #expect(mockUserDefaults.bool(forKey: testPassageKey) == false)
    }

    @Test("No migration when iCloud is unavailable")
    func testICloudMigrationSkippedWhenUnavailable() async throws {
        guard !isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        _ = Plan(userDefaults: mockUserDefaults, store: mockStore)

        #expect(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY) == false)
        #expect(mockStore.object(forKey: "startDate") == nil)
        #expect(mockStore.data(forKey: "selections") == nil)
    }

    @Test("Migration already completed uses iCloud values")
    func testMigrationAlreadyCompleted() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let existingDate = Date(timeIntervalSince1970: 1_640_995_200)
        mockStore.set(existingDate, forKey: "startDate")
        mockStore.set(true, forKey: "selfPaced")

        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)

        #expect(plan.startDate == existingDate)
        #expect(plan.isSelfPaced)
        #expect(mockStore.synchronizeCallCount == 0)
    }

    @Test("Passage completion saves to iCloud after migration")
    func testPassageCompletionWithICloud() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)

        let firstPassage = plan.selections[0].getPassages()[0]
        let initialSyncCount = mockStore.synchronizeCallCount
        firstPassage.read()

        #expect(firstPassage.completed)
        #expect(mockStore.bool(forKey: firstPassage.userDefaultsKeyV2))
        #expect(mockStore.synchronizeCallCount == initialSyncCount + 1)
        #expect(mockUserDefaults.bool(forKey: firstPassage.userDefaultsKeyV2) == false)
    }

    @Test("Passage completion uses iCloud after migration and reload")
    func testPassageCompletionWithoutICloud() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        _ = Plan(userDefaults: mockUserDefaults, store: mockStore)

        #expect(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))

        let reloadedPlan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        let firstPassage = reloadedPlan.selections[0].getPassages()[0]
        firstPassage.read()

        #expect(firstPassage.completed)
        #expect(mockStore.bool(forKey: firstPassage.userDefaultsKeyV2))
    }

    @Test("Setting start date persists to iCloud")
    func testSetStartDateWithICloud() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)

        let newDate = Date(timeIntervalSince1970: 1_640_995_200)
        let initialSyncCount = mockStore.synchronizeCallCount
        plan.setStartDate(to: newDate)

        #expect(plan.startDate == newDate)
        #expect((mockStore.object(forKey: "startDate") as? Date) == newDate)
        #expect(mockStore.synchronizeCallCount == initialSyncCount + 1)
        #expect(mockUserDefaults.object(forKey: "startDate") == nil)
    }

    @Test("Setting self-paced persists to iCloud")
    func testSetSelfPacedWithICloud() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)

        let initialSyncCount = mockStore.synchronizeCallCount
        plan.setSelfPaced(to: true)

        #expect(plan.isSelfPaced)
        #expect(mockStore.bool(forKey: "selfPaced"))
        #expect(mockStore.synchronizeCallCount == initialSyncCount + 1)
        #expect(mockUserDefaults.bool(forKey: "selfPaced") == false)
    }

    @Test("iCloud sync updates plan state")
    func testICloudSyncHandling() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)

        let newDate = Date(timeIntervalSince1970: 1_640_995_200)
        mockStore.set(newDate, forKey: "startDate")
        mockStore.set(true, forKey: "selfPaced")

        let notification = Notification(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: mockStore)
        plan.testHandleICloudSync(notification: notification)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(plan.startDate == newDate)
        #expect(plan.isSelfPaced)
    }

    @Test("Migration tolerates corrupted selections data")
    func testMigrationWithCorruptedSelectionsData() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        let startDate = Date(timeIntervalSince1970: 1_672_531_200)
        mockUserDefaults.set(startDate, forKey: "startDate")
        mockUserDefaults.set(false, forKey: "selfPaced")

        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)

        #expect(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        #expect(mockStore.data(forKey: "selections") != nil)
        #expect(plan.selections.count == RAW_PLAN_DATA.count)
    }

    @Test("iCloud sync with corrupted data falls back to default plan")
    func testICloudSyncWithCorruptedData() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)

        mockStore.set(Data("corrupted".utf8), forKey: "selections")
        let notification = Notification(
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: mockStore)
        plan.testHandleICloudSync(notification: notification)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(plan.selections.count == RAW_PLAN_DATA.count)
    }

    @Test("Migration smoke test with larger data")
    func testMigrationPerformance() async throws {
        guard isICloudAvailable() else { return }

        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        for i in 0..<100 {
            mockUserDefaults.set(true, forKey: "TestPassage\(i)+\(i)")
        }
        mockUserDefaults.set(Date(), forKey: "startDate")
        mockUserDefaults.set(true, forKey: "selfPaced")

        _ = Plan(userDefaults: mockUserDefaults, store: mockStore)
        #expect(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
    }
}
