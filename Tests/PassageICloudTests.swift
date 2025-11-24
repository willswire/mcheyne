//
//  PassageICloudTests.swift
//  mcheyne-plan-tests
//
//  Created by Felipe Salazar on 27.08.25.
//

import XCTest

final class PassageICloudTests: XCTestCase {
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
    
    // MARK: - Passage Initialization Tests
    
    func testPassageInitializationWithICloud() throws {
        // Given: iCloud migration is complete
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        mockStore.set(true, forKey: "Genesis 1+0")
        
        // When: Creating a passage
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: mockStore)
        
        // Then: Should load from iCloud
        XCTAssertTrue(passage.completed)
        XCTAssertEqual(passage.userDefaultsKeyV2, "Genesis 1+0")
    }
    
    func testPassageInitializationWithoutICloud() throws {
        // Given: iCloud migration is not complete
        mockUserDefaults.set(false, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        mockUserDefaults.set(true, forKey: "Genesis 1+0")
        
        // When: Creating a passage
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: mockStore)
        
        // Then: Should load from UserDefaults
        XCTAssertTrue(passage.completed)
        XCTAssertEqual(passage.userDefaultsKeyV2, "Genesis 1+0")
    }
    
    func testPassageInitializationWithoutStore() throws {
        // Given: No store provided
        mockUserDefaults.set(true, forKey: "Genesis 1+0")
        
        // When: Creating a passage without store
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: nil)
        
        // Then: Should load from UserDefaults
        XCTAssertTrue(passage.completed)
    }
    
    // MARK: - Passage Save Tests
    
    func testPassageSaveToICloud() throws {
        // Given: Passage with iCloud
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: mockStore)
        
        // When: Marking as read
        let initialSyncCount = mockStore.synchronizeCallCount
        passage.read()
        
        // Then: Should save to iCloud
        XCTAssertTrue(passage.completed)
        XCTAssertTrue(mockStore.bool(forKey: "Genesis 1+0"))
        XCTAssertEqual(mockStore.synchronizeCallCount, initialSyncCount + 1)
        
        // And: Should not save to UserDefaults
        XCTAssertFalse(mockUserDefaults.bool(forKey: "Genesis 1+0"))
    }
    
    func testPassageSaveToUserDefaults() throws {
        // Given: Passage without iCloud migration
        mockUserDefaults.set(false, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: mockStore)
        
        // When: Marking as read
        passage.read()
        
        // Then: Should save to UserDefaults
        XCTAssertTrue(passage.completed)
        XCTAssertTrue(mockUserDefaults.bool(forKey: "Genesis 1+0"))
        
        // And: Should not save to iCloud
        XCTAssertFalse(mockStore.bool(forKey: "Genesis 1+0"))
    }
    
    func testPassageSaveWithoutStore() throws {
        // Given: Passage without store
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: nil)
        
        // When: Marking as read
        passage.read()
        
        // Then: Should save to UserDefaults
        XCTAssertTrue(passage.completed)
        XCTAssertTrue(mockUserDefaults.bool(forKey: "Genesis 1+0"))
    }
    
    func testPassageUnread() throws {
        // Given: Completed passage with iCloud
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: mockStore)
        passage.read()
        
        // When: Marking as unread
        let initialSyncCount = mockStore.synchronizeCallCount
        passage.unread()
        
        // Then: Should update iCloud
        XCTAssertFalse(passage.completed)
        XCTAssertFalse(mockStore.bool(forKey: "Genesis 1+0"))
        XCTAssertEqual(mockStore.synchronizeCallCount, initialSyncCount + 1)
    }
    
    // MARK: - ReadingSelection Tests
    
    func testReadingSelectionWithICloud() throws {
        // Given: iCloud migration complete
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let references = ["Genesis 1", "Genesis 2", "Genesis 3", "Genesis 4"]
        
        // When: Creating reading selection
        let selection = ReadingSelection(references, userDefaults: mockUserDefaults, store: mockStore)
        
        // Then: All passages should have store reference
        let passages = selection.getPassages()
        XCTAssertEqual(passages.count, 4)
        
        for (index, passage) in passages.enumerated() {
            XCTAssertEqual(passage.description, references[index])
            XCTAssertNotNil(passage.store)
            XCTAssertEqual(passage.userDefaultsKeyV2, "\(references[index])+\(index)")
        }
    }
    
    func testReadingSelectionWithoutICloud() throws {
        // Given: No iCloud store
        let references = ["Genesis 1", "Genesis 2", "Genesis 3", "Genesis 4"]
        
        // When: Creating reading selection without store
        let selection = ReadingSelection(references, userDefaults: mockUserDefaults, store: nil)
        
        // Then: All passages should not have store reference
        let passages = selection.getPassages()
        for passage in passages {
            XCTAssertNil(passage.store)
        }
    }
    
    func testReadingSelectionCompletion() throws {
        // Given: Reading selection with iCloud
        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let references = ["Genesis 1", "Genesis 2"]
        let selection = ReadingSelection(references, userDefaults: mockUserDefaults, store: mockStore)
        
        // When: Marking first passage as read
        selection[0].read()
        
        // Then: Selection should not be complete
        XCTAssertFalse(selection.isComplete())
        
        // When: Marking second passage as read
        selection[1].read()
        
        // Then: Selection should be complete
        XCTAssertTrue(selection.isComplete())
    }
    
    // MARK: - Key Generation Tests
    
    func testPassageKeyGeneration() throws {
        let testCases = [
            ("Genesis 1", 0, "Genesis 1+0"),
            ("Exodus 20", 3, "Exodus 20+3"),
            ("1 Chronicles 1-2", 1, "1 Chronicles 1-2+1"),
            ("Psalm 119:1-88", 2, "Psalm 119:1-88+2")
        ]
        
        for (reference, id, expectedKey) in testCases {
            let passage = Passage(reference, id: id, userDefaults: mockUserDefaults, store: mockStore)
            XCTAssertEqual(passage.userDefaultsKeyV2, expectedKey)
        }
    }
}
