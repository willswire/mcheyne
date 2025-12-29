//
//  MockUserDefaultsTests.swift
//  The M'Cheyne Plan
//
//  Created by Andrew Burks on 7/23/23.
//

import Foundation
import Testing

@Suite("MockUserDefaults")
struct MockUserDefaultsTests {

    @Test("Setting an object stores value by key")
    func testSettingAnObject() async throws {
        let ud = MockUserDefaults()

        let testObject = "TestValue"
        let testKey = "TestKey"

        ud.set(testObject, forKey: testKey)

        let expectedResult: [String: AnyHashable] = [testKey: testObject]
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResult))
    }

    @Test("Setting a Bool stores value by key")
    func testSettingABool() async throws {
        let ud = MockUserDefaults()

        let testValue = true
        let testKey = "TestKey"

        ud.set(testValue, forKey: testKey)

        let expectedResult: [String: AnyHashable] = [testKey: testValue]
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResult))
    }

    @Test("Removing an object clears value for key")
    func testRemovingAnObject() async throws {
        let ud = MockUserDefaults()

        let testObject = "TestValue"
        let testKey = "TestKey"

        ud.set(testObject, forKey: testKey)

        let expectedResult: [String: AnyHashable] = [testKey: testObject]
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResult))

        // Removal
        ud.removeObject(forKey: testKey)

        let expectedResultAfterRemoval: [String: Any] = [:]
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResultAfterRemoval))
    }

    @Test("Removing a Bool clears value for key")
    func testRemovingABool() async throws {
        let ud = MockUserDefaults()

        let testValue = true
        let testKey = "TestKey"

        ud.set(testValue, forKey: testKey)

        let expectedResult: [String: AnyHashable] = [testKey: testValue]
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResult))

        // Removal
        ud.removeObject(forKey: testKey)

        let expectedResultAfterRemoval: [String: Any] = [:]
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResultAfterRemoval))
    }
}

