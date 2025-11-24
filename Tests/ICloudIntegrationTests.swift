//
//  ICloudIntegrationTests.swift
//  mcheyne-plan-tests
//
//  Created by Felipe Salazar on 27.08.25.
//

import XCTest

final class ICloudIntegrationTests: XCTestCase {
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
    
    // MARK: - Full Migration Flow Tests
    
    func testCompleteUserJourneyFromV1ToICloud() throws {
        // Step 1: User has V1 schema data
        setupV1SchemaData()
        
        // Step 2: User opens app - should migrate to V2 and then to iCloud
        let plan = Plan(userDefaults: mockUserDefaults, store: mockStore)
        
        // Verify V2 migration completed
        XCTAssertTrue(mockUserDefaults.bool(forKey: MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY))
        
        // Verify iCloud migration completed
        XCTAssertTrue(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        
        // Verify data is in iCloud
        XCTAssertNotNil(mockStore.object(forKey: "startDate"))
        XCTAssertNotNil(mockStore.data(forKey: "selections"))
        
        // Verify some passage completions were migrated
        let firstSelection = plan.selections[0]
        let firstPassage = firstSelection.getPassages()[0]
        XCTAssertTrue(mockStore.bool(forKey: firstPassage.userDefaultsKeyV2))
        
        // Step 3: User marks a new passage as read
        let secondPassage = firstSelection.getPassages()[1]
        secondPassage.read()
        
        // Verify it saves to iCloud
        XCTAssertTrue(mockStore.bool(forKey: secondPassage.userDefaultsKeyV2))
        
        // Step 4: User changes settings
        plan.setSelfPaced(to: true)
        XCTAssertTrue(mockStore.bool(forKey: "selfPaced"))
        
        let newStartDate = Date(timeIntervalSince1970: 1640995200)
        plan.setStartDate(to: newStartDate)
        XCTAssertEqual(mockStore.object(forKey: "startDate") as? Date, newStartDate)
    }
    
    func testDeviceSyncScenario() throws {
        // Simulate Device 1: User completes some readings
        let device1UserDefaults = MockUserDefaults()
        let device1Store = MockUbiquitousKeyValueStore()
        
        let plan1 = Plan(userDefaults: device1UserDefaults, store: device1Store)
        
        // User reads first 3 passages on device 1
        for i in 0..<3 {
            plan1.selections[0].getPassages()[i].read()
        }
        plan1.setSelfPaced(to: true)
        
        // Simulate Device 2: Receives sync from iCloud
        let device2UserDefaults = MockUserDefaults()
        device2UserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        
        // Copy iCloud data to simulate sync
        let device2Store = MockUbiquitousKeyValueStore()
        device2Store.persistedDictionary = device1Store.persistedDictionary
        
        let plan2 = Plan(userDefaults: device2UserDefaults, store: device2Store)
        
        // Verify device 2 has the same state as device 1
        XCTAssertTrue(plan2.isSelfPaced)
        XCTAssertEqual(plan2.startDate.timeIntervalSince1970, plan1.startDate.timeIntervalSince1970, accuracy: 1.0)
        
        // Verify passage completions are synced
        for i in 0..<3 {
            XCTAssertTrue(plan2.selections[0].getPassages()[i].completed)
        }
        XCTAssertFalse(plan2.selections[0].getPassages()[3].completed)
    }
    
    func testConflictResolutionScenario() throws {
        // Setup: Two devices with the same initial state
        let device1UserDefaults = MockUserDefaults()
        let device1Store = MockUbiquitousKeyValueStore()
        device1UserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        
        let device2UserDefaults = MockUserDefaults()
        let device2Store = MockUbiquitousKeyValueStore()
        device2UserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        
        // Copy initial state
        let baseStartDate = Date(timeIntervalSince1970: 1640995200)
        device1Store.set(baseStartDate, forKey: "startDate")
        device2Store.set(baseStartDate, forKey: "startDate")
        
        let plan1 = Plan(userDefaults: device1UserDefaults, store: device1Store)
        let plan2 = Plan(userDefaults: device2UserDefaults, store: device2Store)
        
        // Device 1: User reads passage A
        plan1.selections[0].getPassages()[0].read()
        
        // Device 2: User reads passage B (offline, different passage)
        plan2.selections[0].getPassages()[1].read()
        
        // Simulate sync: Device 2 receives Device 1's changes
        device2Store.persistedDictionary = device1Store.persistedDictionary
        
        let notification = Notification(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: device2Store)
        plan2.testHandleICloudSync(notification: notification)
        
        // Give time for async update
        let expectation = XCTestExpectation(description: "Sync completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify Device 2 now has Device 1's state
        XCTAssertTrue(plan2.selections[0].getPassages()[0].completed) // From Device 1
        
        // Note: In this implementation, Device 2's local change (passage B) would be lost
        // This is expected behavior with NSUbiquitousKeyValueStore - last writer wins
    }
    
    func testOfflineToOnlineTransition() throws {
        // Step 1: User uses app offline (no iCloud migration)
        let offlineUserDefaults = MockUserDefaults()
        let plan = Plan(userDefaults: offlineUserDefaults, store: mockStore)
        
        // User reads some passages offline
        for i in 0..<5 {
            plan.selections[0].getPassages()[i].read()
        }
        plan.setSelfPaced(to: true)
        
        // Verify data is in iCloud (migration happened automatically)
        XCTAssertTrue(offlineUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        XCTAssertTrue(mockStore.bool(forKey: "selfPaced"))
        
        for i in 0..<5 {
            let passage = plan.selections[0].getPassages()[i]
            XCTAssertTrue(mockStore.bool(forKey: passage.userDefaultsKeyV2))
        }
    }
    
    func testDataIntegrityAfterMultipleMigrations() throws {
        // Setup initial V1 data
        setupV1SchemaData()
        
        // First migration: V1 -> V2
        let planV2 = Plan(userDefaults: mockUserDefaults, store: MockUbiquitousKeyValueStore())
        XCTAssertTrue(mockUserDefaults.bool(forKey: MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY))
        
        // Verify V2 data exists
        let firstPassage = planV2.selections[0].getPassages()[0]
        XCTAssertTrue(mockUserDefaults.bool(forKey: firstPassage.userDefaultsKeyV2))
        
        // Second migration: V2 -> iCloud
        let planICloud = Plan(userDefaults: mockUserDefaults, store: mockStore)
        XCTAssertTrue(mockUserDefaults.bool(forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY))
        
        // Verify data integrity
        XCTAssertTrue(mockStore.bool(forKey: firstPassage.userDefaultsKeyV2))
        XCTAssertNotNil(mockStore.object(forKey: "startDate"))
        XCTAssertNotNil(mockStore.data(forKey: "selections"))
        
        // Verify UserDefaults cleanup happened
        XCTAssertNil(mockUserDefaults.object(forKey: "startDate"))
        XCTAssertFalse(mockUserDefaults.bool(forKey: firstPassage.userDefaultsKeyV2))
    }
    
    // MARK: - Helper Methods
    
    private func setupV1SchemaData() {
        // Add some V1 schema data (old format)
        let sampleV1Keys = Array(USER_DEFAULTS_SCHEMA_V1_KEYS.prefix(10))
        for (index, key) in sampleV1Keys.enumerated() {
            // Mark first 5 as completed in V1 format
            mockUserDefaults.set(index < 5, forKey: key)
        }
        
        // Add basic settings
        mockUserDefaults.set(Date(timeIntervalSince1970: 1640995200), forKey: "startDate")
        mockUserDefaults.set(false, forKey: "selfPaced")
    }
}

// Extension for testing
extension ICloudIntegrationTests {
    func testHandleICloudSync(plan: Plan, notification: Notification) {
        plan.testHandleICloudSync(notification: notification)
    }
}

extension Plan {
    func testHandleICloudSync(notification: Notification) {
        self.handleICloudSync(notification: notification)
    }
}
