//
//  MockUserDefaultsTests.swift
//  mcheyne-plan-tests
//
//  Created by Andrew Burks on 7/23/23.
//

import XCTest

final class MockUserDefaultsTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSettingAnObject() throws {
        let ud: MockUserDefaults = MockUserDefaults()
        
        let testObject: String = "TestValue"
        let testKey: String = "TestKey"
        
        ud.set(testObject, forKey: testKey)
        
        let expectedResult: Dictionary<String, AnyHashable> = [testKey: testObject]
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResult))
    }
    
    func testSettingABool() throws {
        let ud: MockUserDefaults = MockUserDefaults()
        
        let testValue: Bool = true
        let testKey: String = "TestKey"
        
        ud.set(testValue, forKey: testKey)
        
        let expectedResult: Dictionary<String, AnyHashable> = [testKey: testValue]
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResult))
    }
    
    func testRemovingAnObject() {
        let ud: MockUserDefaults = MockUserDefaults()
        
        let testObject: String = "TestValue"
        let testKey: String = "TestKey"
        
        ud.set(testObject, forKey: testKey)
        
        let expectedResult: Dictionary<String, AnyHashable> = [testKey: testObject]
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResult))
        
        // Removal
        ud.removeObject(forKey: testKey)
        
        let expectedResultAfterRemoval: Dictionary<String, Any> = [:]
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResultAfterRemoval))
    }
    
    func testRemovingABool() {
        let ud: MockUserDefaults = MockUserDefaults()
        
        let testValue: Bool = true
        let testKey: String = "TestKey"
        
        ud.set(testValue, forKey: testKey)
        
        let expectedResult: Dictionary<String, AnyHashable> = [testKey: testValue]
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResult))
        
        // Removal
        ud.removeObject(forKey: testKey)
        
        let expectedResultAfterRemoval: Dictionary<String, Any> = [:]
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedResultAfterRemoval))
    }
}
