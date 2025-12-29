//
//  PassageICloudTests.swift
//  The M'Cheyne Plan
//
//  Migrated to Swift Testing on 1/4/26.
//

import Foundation
import Testing

@Suite("Passage iCloud")
struct PassageICloudTests {
    @Test("Initialization uses iCloud when migration is complete")
    func testPassageInitializationWithICloud() async throws {
        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        mockStore.set(true, forKey: "Genesis 1+0")

        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: mockStore)

        #expect(passage.completed)
        #expect(passage.userDefaultsKeyV2 == "Genesis 1+0")
    }

    @Test("Initialization uses UserDefaults when migration is incomplete")
    func testPassageInitializationWithoutICloud() async throws {
        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(false, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        mockUserDefaults.set(true, forKey: "Genesis 1+0")

        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: mockStore)

        #expect(passage.completed)
        #expect(passage.userDefaultsKeyV2 == "Genesis 1+0")
    }

    @Test("Initialization uses UserDefaults when no store is provided")
    func testPassageInitializationWithoutStore() async throws {
        let mockUserDefaults = MockUserDefaults()

        mockUserDefaults.set(true, forKey: "Genesis 1+0")

        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: nil)

        #expect(passage.completed)
    }

    @Test("Read saves to iCloud when migration is complete")
    func testPassageSaveToICloud() async throws {
        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: mockStore)

        let initialSyncCount = mockStore.synchronizeCallCount
        passage.read()

        #expect(passage.completed)
        #expect(mockStore.bool(forKey: "Genesis 1+0"))
        #expect(mockStore.synchronizeCallCount == initialSyncCount + 1)
        #expect(mockUserDefaults.bool(forKey: "Genesis 1+0") == false)
    }

    @Test("Read saves to UserDefaults when migration is incomplete")
    func testPassageSaveToUserDefaults() async throws {
        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(false, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: mockStore)

        passage.read()

        #expect(passage.completed)
        #expect(mockUserDefaults.bool(forKey: "Genesis 1+0"))
        #expect(mockStore.bool(forKey: "Genesis 1+0") == false)
    }

    @Test("Read saves to UserDefaults when no store is provided")
    func testPassageSaveWithoutStore() async throws {
        let mockUserDefaults = MockUserDefaults()
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: nil)

        passage.read()

        #expect(passage.completed)
        #expect(mockUserDefaults.bool(forKey: "Genesis 1+0"))
    }

    @Test("Unread updates iCloud state")
    func testPassageUnread() async throws {
        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let passage = Passage("Genesis 1", id: 0, userDefaults: mockUserDefaults, store: mockStore)
        passage.read()

        let initialSyncCount = mockStore.synchronizeCallCount
        passage.unread()

        #expect(passage.completed == false)
        #expect(mockStore.bool(forKey: "Genesis 1+0") == false)
        #expect(mockStore.synchronizeCallCount == initialSyncCount + 1)
    }

    @Test("Reading selection wires iCloud store")
    func testReadingSelectionWithICloud() async throws {
        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let references = ["Genesis 1", "Genesis 2", "Genesis 3", "Genesis 4"]

        let selection = ReadingSelection(
            references, userDefaults: mockUserDefaults, store: mockStore)
        let passages = selection.getPassages()

        #expect(passages.count == 4)
        for (index, passage) in passages.enumerated() {
            #expect(passage.description == references[index])
            #expect(passage.store != nil)
            #expect(passage.userDefaultsKeyV2 == "\(references[index])+\(index)")
        }
    }

    @Test("Reading selection without iCloud store")
    func testReadingSelectionWithoutICloud() async throws {
        let mockUserDefaults = MockUserDefaults()
        let references = ["Genesis 1", "Genesis 2", "Genesis 3", "Genesis 4"]

        let selection = ReadingSelection(references, userDefaults: mockUserDefaults, store: nil)
        let passages = selection.getPassages()

        for passage in passages {
            #expect(passage.store == nil)
        }
    }

    @Test("Reading selection completion is derived from passages")
    func testReadingSelectionCompletion() async throws {
        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        mockUserDefaults.set(true, forKey: MIGRATION_TO_ICLOUD_COMPLETE_KEY)
        let references = ["Genesis 1", "Genesis 2"]
        let selection = ReadingSelection(
            references, userDefaults: mockUserDefaults, store: mockStore)

        selection[0].read()
        #expect(selection.isComplete() == false)

        selection[1].read()
        #expect(selection.isComplete())
    }

    @Test("Passage key generation")
    func testPassageKeyGeneration() async throws {
        let mockUserDefaults = MockUserDefaults()
        let mockStore = MockUbiquitousKeyValueStore()

        let testCases = [
            ("Genesis 1", 0, "Genesis 1+0"),
            ("Exodus 20", 3, "Exodus 20+3"),
            ("1 Chronicles 1-2", 1, "1 Chronicles 1-2+1"),
            ("Psalm 119:1-88", 2, "Psalm 119:1-88+2"),
        ]

        for (reference, id, expectedKey) in testCases {
            let passage = Passage(
                reference, id: id, userDefaults: mockUserDefaults, store: mockStore)
            #expect(passage.userDefaultsKeyV2 == expectedKey)
        }
    }
}
