//
//  PlanTests.swift
//  mcheyne-plan-tests
//
//  Created by Andrew Burks on 7/22/23.
//

import XCTest

private let INDEX_OF_FIRST_SELECTION_WITH_REPEATED_PASSAGE: Int = 171

final class PlanTests: XCTestCase {
    var ud: MockUserDefaults = MockUserDefaults()
    var planWithV2Schema: Array<Array<String>> = []
    
    override func setUpWithError() throws {
        ud = MockUserDefaults() // Always set up a clean userDefaults instance
        if planWithV2Schema.count == 0 {
            planWithV2Schema = createPlanWithV2Schema()
        }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTotalNumberOfEntriesInPlan() throws {
        let expectedTotalNumberOfEntriesInPlan: Int = (365 * 4) + 2 // Includes 'startDate' entry and 'migrationToV2Schema' entry
        var _: Plan = Plan(userDefaults: ud)
        
        XCTAssertEqual(expectedTotalNumberOfEntriesInPlan, ud.dictionaryRepresentation().count)
    }
    
    func testAllFalseWithV2Schema() throws {
        var expectedUserDefaults: Dictionary<String, AnyHashable> = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: 0)
        setStartDateForBothExpectedAndActual(expectedUserDefaults: &expectedUserDefaults)
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        var _: Plan = Plan(userDefaults: ud)
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }
    
    func testSixMonthsCompleteMigration() throws {
        var expectedUserDefaults: Dictionary<String, AnyHashable> = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: 365 / 2)
        ud.persistedDictionary = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: 365 / 2)
        setStartDateForBothExpectedAndActual(expectedUserDefaults: &expectedUserDefaults)
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        var _: Plan = Plan(userDefaults: ud)
        var _: Dictionary<String, AnyHashable> = getDifferenceBetweenDictionaries(a: expectedUserDefaults,
                                                                                  b: Dictionary(_immutableCocoaDictionary: NSDictionary(dictionary: ud.dictionaryRepresentation())))
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }
    
    func testSixMonthsCompleteWithPartialMigration() throws {
        var expectedUserDefaults: Dictionary<String, AnyHashable> = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: 365 / 2)
        let sixMonthsCompleteWithV1Schema = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: 365 / 2)
        let sixMonthsCompleteWithPartialV1Schema = sixMonthsCompleteWithV1Schema.filter( { !$0.key.contains("1 Chronicles") } )
        
        ud.persistedDictionary = sixMonthsCompleteWithPartialV1Schema
        setStartDateForBothExpectedAndActual(expectedUserDefaults: &expectedUserDefaults)
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        var _: Plan = Plan(userDefaults: ud)
        var _: Dictionary<String, AnyHashable> = getDifferenceBetweenDictionaries(a: expectedUserDefaults,
                                                                                  b: Dictionary(_immutableCocoaDictionary: NSDictionary(dictionary: ud.dictionaryRepresentation())))
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }
    
    func testAllCompleteMigration() throws {
        var expectedUserDefaults: Dictionary<String, AnyHashable> = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: 365)
        ud.persistedDictionary = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: 365)
        setStartDateForBothExpectedAndActual(expectedUserDefaults: &expectedUserDefaults)
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        var _: Plan = Plan(userDefaults: ud)
        var _: Dictionary<String, AnyHashable> = getDifferenceBetweenDictionaries(a: expectedUserDefaults,
                                                                                  b: Dictionary(_immutableCocoaDictionary: NSDictionary(dictionary: ud.dictionaryRepresentation())))
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }
    
    func testAllCompleteButLastDayMigration() throws {
        var expectedUserDefaults: Dictionary<String, AnyHashable> = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: 364)
        ud.persistedDictionary = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: 364)
        setStartDateForBothExpectedAndActual(expectedUserDefaults: &expectedUserDefaults)
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        var _: Plan = Plan(userDefaults: ud)
        var _: Dictionary<String, AnyHashable> = getDifferenceBetweenDictionaries(a: expectedUserDefaults,
                                                                                  b: Dictionary(_immutableCocoaDictionary: NSDictionary(dictionary: ud.dictionaryRepresentation())))
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }
    
    func testNoRepeatedPassagesCompleteMigration() throws {
        var expectedUserDefaults: Dictionary<String, AnyHashable> = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: INDEX_OF_FIRST_SELECTION_WITH_REPEATED_PASSAGE)
        ud.persistedDictionary = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: INDEX_OF_FIRST_SELECTION_WITH_REPEATED_PASSAGE)
        setStartDateForBothExpectedAndActual(expectedUserDefaults: &expectedUserDefaults)
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        var _: Plan = Plan(userDefaults: ud)
        var _: Dictionary<String, AnyHashable> = getDifferenceBetweenDictionaries(a: expectedUserDefaults,
                                                                                  b: Dictionary(_immutableCocoaDictionary: NSDictionary(dictionary: ud.dictionaryRepresentation())))
        XCTAssertTrue(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }
    
    func testPerformanceOfMigration() throws {
        let sixMonthsCompleteWithV1Schema = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: 365 / 2)
        measure {
            ud.persistedDictionary = sixMonthsCompleteWithV1Schema
            var _: Plan = Plan(userDefaults: ud)
        }
    }
    
    // Helper functions
    
    private func setStartDateForBothExpectedAndActual(expectedUserDefaults: inout Dictionary<String, AnyHashable>) {
        let startDate: Date = Date()
        expectedUserDefaults["startDate"] = startDate
        ud.set(startDate, forKey: "startDate")
    }
    
    private func getDifferenceBetweenDictionaries(a: Dictionary<String, AnyHashable>, b: Dictionary<String, AnyHashable>) -> Dictionary<String, AnyHashable> {
        var results: Dictionary<String, AnyHashable> = [:]
        
        a.forEach { (key: String, value: AnyHashable) in
            if b[key] != value {
                results[key] = [value, b[key]]
            }
        }

        return results
    }
    
    private func createPlanWithV2Schema() -> Array<Array<String>> {
        let planWithV2Schema: Array<Array<String>> = RAW_PLAN_DATA.map { selection in
            selection.map { passage in
                passage + "+" + String(selection.firstIndex(of: passage)!)
            }
        }
        
        return planWithV2Schema
    }
    
    private func createUserDefaultsDictionary(rawPlan: Array<Array<String>>, selectionIndexToStartMarkingFalse: Int) -> Dictionary<String, AnyHashable> {
        var userDefaultsDictionary: Dictionary<String, AnyHashable> = [:]
        
        for selection in rawPlan {
            let completedValue: Bool = rawPlan.firstIndex(of: selection)! < selectionIndexToStartMarkingFalse
            for passage in selection {
                
                // If the key already exists then don't update it because the v1 schema would have overwrites
                if userDefaultsDictionary.index(forKey: passage) != nil {
                    continue
                }
                
                userDefaultsDictionary[passage] = completedValue
            }
        }
        
        return userDefaultsDictionary
    }
}
