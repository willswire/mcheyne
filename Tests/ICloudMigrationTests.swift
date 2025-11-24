//
//  ICloudMigrationTests.swift
//  mcheyne-plan-tests
//
//  Created by Felipe Salazar on 27.08.25.
//

import XCTest

final class ICloudMigrationTests: XCTestCase {
    var mockUserDefaults: MockUserDefaults!
    var mockStore: MockUbiquitousKeyValueStore!
    
    override func setUpWithError() throws {
        mockUserDefaults = MockUserDefaults()
        mockStore = MockUbiquitousKeyValueStore()
    }

    override func tearDownWithError() throws {
        mockUserDefaults = nil
        mockStore = nil
    }
    
    // MARK: - Migration Tests
    
    func testICloudMigrationWithEmptyUserDefaults() throws {
        // When: Creating a plan with empty UserDefaults
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // Then: iCloud should contain the basic values
        XCTAssertNotNil(mockStore.object(forKey: "startDate"))
        XCTAssertFalse(mockStore.bool(forKey: "selfPaced"))
        XCTAssertNotNil(mockStore.data(forKey: "selections"))
        XCTAssertTrue(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        XCTAssertTrue(mockStore.synchronizeCallCount > 0)
    }
    
    func testICloudMigrationWithExistingUserDefaultsData() throws {
        // Given: UserDefaults with existing data
        let startDate = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
        mockUserDefaults.set(startDate, forKey: "startDate")
        mockUserDefaults.set(true, forKey: "selfPaced")
        
        // Add some passage completion data
        let testPassageKey = "Genesis 1+0"
        mockUserDefaults.set(true, forKey: testPassageKey)
        
        // When: Creating a plan
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // Then: Data should be migrated to iCloud
        XCTAssertEqual(mockStore.object(forKey: "startDate") as? Date, startDate)
        XCTAssertTrue(mockStore.bool(forKey: "selfPaced"))
        XCTAssertTrue(mockStore.bool(forKey: testPassageKey))
        XCTAssertTrue(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        
        // And: Old UserDefaults data should be cleaned up
        XCTAssertNil(mockUserDefaults.object(forKey: "startDate"))
        XCTAssertFalse(mockUserDefaults.bool(forKey: "selfPaced"))
        XCTAssertFalse(mockUserDefaults.bool(forKey: testPassageKey))
    }
    
    func testMigrationAlreadyCompleted() throws {
        // Given: Migration already completed
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        
        // And: iCloud has existing data
        let existingDate = Date(timeIntervalSince1970: 1640995200)
        mockStore.set(existingDate, forKey: "startDate")
        mockStore.set(true, forKey: "selfPaced")
        
        // When: Creating a plan
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // Then: Should use iCloud data without re-migrating
        XCTAssertEqual(plan.startDate, existingDate)
        XCTAssertTrue(plan.isSelfPaced)
        XCTAssertEqual(mockStore.synchronizeCallCount, 0) // No new synchronization calls
    }
    
    func testPassageCompletionWithICloud() throws {
        // Given: Plan with iCloud migration completed
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // When: Marking a passage as read
        let firstPassage = plan.selections[0].getPassages()[0]
        let initialSyncCount = mockStore.synchronizeCallCount
        firstPassage.read()
        
        // Then: Should save to iCloud
        XCTAssertTrue(firstPassage.completed)
        XCTAssertTrue(mockStore.bool(forKey: firstPassage.userDefaultsKeyV2))
        XCTAssertEqual(mockStore.synchronizeCallCount, initialSyncCount + 1)
        
        // And: Should not save to UserDefaults
        XCTAssertFalse(mockUserDefaults.bool(forKey: firstPassage.userDefaultsKeyV2))
    }
    
    func testPassageCompletionWithoutICloud() throws {
        // Given: Plan without iCloud (migration not completed)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // Then: Migration should be completed automatically
        XCTAssertTrue(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        
        // When: Marking a passage as read (after migration)
        let firstPassage = plan.selections[0].getPassages()[0]
        firstPassage.read()
        
        // Then: Should save to iCloud (since migration is now complete)
        XCTAssertTrue(firstPassage.completed)
        XCTAssertTrue(mockStore.bool(forKey: firstPassage.userDefaultsKeyV2))
    }
    
    func testSetStartDateWithICloud() throws {
        // Given: Plan with iCloud
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // When: Setting start date
        let newDate = Date(timeIntervalSince1970: 1640995200)
        let initialSyncCount = mockStore.synchronizeCallCount
        plan.setStartDate(to: newDate)
        
        // Then: Should save to iCloud
        XCTAssertEqual(plan.startDate, newDate)
        XCTAssertEqual(mockStore.object(forKey: "startDate") as? Date, newDate)
        XCTAssertEqual(mockStore.synchronizeCallCount, initialSyncCount + 1)
        
        // And: Should not save to UserDefaults
        XCTAssertNil(mockUserDefaults.object(forKey: "startDate"))
    }
    
    func testSetSelfPacedWithICloud() throws {
        // Given: Plan with iCloud
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // When: Setting self-paced mode
        let initialSyncCount = mockStore.synchronizeCallCount
        plan.setSelfPaced(to: true)
        
        // Then: Should save to iCloud
        XCTAssertTrue(plan.isSelfPaced)
        XCTAssertTrue(mockStore.bool(forKey: "selfPaced"))
        XCTAssertEqual(mockStore.synchronizeCallCount, initialSyncCount + 1)
        
        // And: Should not save to UserDefaults
        XCTAssertFalse(mockUserDefaults.bool(forKey: "selfPaced"))
    }
    
    func testICloudSyncHandling() throws {
        // Given: Plan with iCloud
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // When: Simulating iCloud sync with new data
        let newDate = Date(timeIntervalSince1970: 1640995200)
        mockStore.set(newDate, forKey: "startDate")
        mockStore.set(true, forKey: "selfPaced")
        
        // Simulate the notification
        let notification = Notification(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: mockStore)
        plan.testHandleICloudSync(notification: notification)
        
        // Give a moment for the async dispatch
        let expectation = XCTestExpectation(description: "iCloud sync completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: Plan should be updated with iCloud data
        XCTAssertEqual(plan.startDate, newDate)
        XCTAssertTrue(plan.isSelfPaced)
    }
    
    // MARK: - Error Handling Tests
    
    func testMigrationWithCorruptedSelectionsData() throws {
        // Given: UserDefaults with existing data
        mockUserDefaults.set(Date(), forKey: "startDate")
        mockUserDefaults.set(false, forKey: "selfPaced")
        
        // When: Creating a plan (migration will happen)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // Then: Should complete migration even with corrupted data
        XCTAssertTrue(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        XCTAssertNotNil(mockStore.data(forKey: "selections"))
        XCTAssertEqual(plan.selections.count, RAW_PLAN_DATA.count)
    }
    
    func testICloudSyncWithCorruptedData() throws {
        // Given: Plan with iCloud
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // When: iCloud has corrupted selections data
        mockStore.set(Data("corrupted".utf8), forKey: "selections")
        
        let notification = Notification(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: mockStore)
        plan.testHandleICloudSync(notification: notification)
        
        // Give a moment for the async dispatch
        let expectation = XCTestExpectation(description: "iCloud sync completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then: Should fall back to default plan data
        XCTAssertEqual(plan.selections.count, RAW_PLAN_DATA.count)
    }
    
    // MARK: - Performance Tests
    
    func testMigrationPerformance() throws {
        // Given: Large amount of passage completion data
        for i in 0..<100 {
            mockUserDefaults.set(true, forKey: "TestPassage\(i)+\(i)")
        }
        mockUserDefaults.set(Date(), forKey: "startDate")
        mockUserDefaults.set(true, forKey: "selfPaced")
        
        // When: Measuring migration performance
        measure {
            let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
            XCTAssertTrue(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        }
    }
}

// Extension to make handleICloudSync testable
extension Plan {
    func testHandleICloudSync(notification: Notification) {
        self.handleICloudSync(notification: notification)
    }
}
