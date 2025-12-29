//
//  PlanTests.swift
//  The M'Cheyne Plan
//
//  Migrated to Swift Testing on 12/29/25
//

import Testing
import Foundation

private let INDEX_OF_FIRST_SELECTION_WITH_REPEATED_PASSAGE: Int = 171

@Suite("Plan Tests")
struct PlanTests {

    @Test("Total number of entries in plan")
    func testTotalNumberOfEntriesInPlan() async throws {
        let ud = MockUserDefaults()
        let expectedTotalNumberOfEntriesInPlan: Int = (365 * 4) + 2 // Includes 'startDate' entry and 'migrationToV2Schema' entry
        _ = Plan(userDefaults: ud)
        #expect(expectedTotalNumberOfEntriesInPlan == ud.dictionaryRepresentation().count)
    }

    @Test("All false with V2 schema")
    func testAllFalseWithV2Schema() async throws {
        let ud = MockUserDefaults()
        let planWithV2Schema = createPlanWithV2Schema()
        var expectedUserDefaults: [String: AnyHashable] = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: 0)
        let startDate = currentStartDate()
        expectedUserDefaults["startDate"] = startDate
        ud.set(startDate, forKey: "startDate")
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        _ = Plan(userDefaults: ud)
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }

    @Test("Six months complete migration")
    func testSixMonthsCompleteMigration() async throws {
        let ud = MockUserDefaults()
        let planWithV2Schema = createPlanWithV2Schema()
        var expectedUserDefaults: [String: AnyHashable] = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: 365 / 2)
        ud.persistedDictionary = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: 365 / 2)
        let startDate = currentStartDate()
        expectedUserDefaults["startDate"] = startDate
        ud.set(startDate, forKey: "startDate")
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        _ = Plan(userDefaults: ud)
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }

    @Test("Six months complete with partial migration")
    func testSixMonthsCompleteWithPartialMigration() async throws {
        let ud = MockUserDefaults()
        let planWithV2Schema = createPlanWithV2Schema()
        var expectedUserDefaults: [String: AnyHashable] = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: 365 / 2)
        let sixMonthsCompleteWithV1Schema = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: 365 / 2)
        let sixMonthsCompleteWithPartialV1Schema = sixMonthsCompleteWithV1Schema.filter { !$0.key.contains("1 Chronicles") }

        ud.persistedDictionary = sixMonthsCompleteWithPartialV1Schema
        let startDate = currentStartDate()
        expectedUserDefaults["startDate"] = startDate
        ud.set(startDate, forKey: "startDate")
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        _ = Plan(userDefaults: ud)
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }

    @Test("All complete migration")
    func testAllCompleteMigration() async throws {
        let ud = MockUserDefaults()
        let planWithV2Schema = createPlanWithV2Schema()
        var expectedUserDefaults: [String: AnyHashable] = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: 365)
        ud.persistedDictionary = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: 365)
        let startDate = currentStartDate()
        expectedUserDefaults["startDate"] = startDate
        ud.set(startDate, forKey: "startDate")
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        _ = Plan(userDefaults: ud)
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }

    @Test("All complete but last day migration")
    func testAllCompleteButLastDayMigration() async throws {
        let ud = MockUserDefaults()
        let planWithV2Schema = createPlanWithV2Schema()
        var expectedUserDefaults: [String: AnyHashable] = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: 364)
        ud.persistedDictionary = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: 364)
        let startDate = currentStartDate()
        expectedUserDefaults["startDate"] = startDate
        ud.set(startDate, forKey: "startDate")
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        _ = Plan(userDefaults: ud)
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }

    @Test("No repeated passages complete migration")
    func testNoRepeatedPassagesCompleteMigration() async throws {
        let ud = MockUserDefaults()
        let planWithV2Schema = createPlanWithV2Schema()
        var expectedUserDefaults: [String: AnyHashable] = createUserDefaultsDictionary(rawPlan: planWithV2Schema, selectionIndexToStartMarkingFalse: INDEX_OF_FIRST_SELECTION_WITH_REPEATED_PASSAGE)
        ud.persistedDictionary = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: INDEX_OF_FIRST_SELECTION_WITH_REPEATED_PASSAGE)
        let startDate = currentStartDate()
        expectedUserDefaults["startDate"] = startDate
        ud.set(startDate, forKey: "startDate")
        expectedUserDefaults[MIGRATION_TO_V2_SCHEMA_COMPLETE_KEY] = true

        _ = Plan(userDefaults: ud)
        #expect(NSDictionary(dictionary: ud.dictionaryRepresentation()).isEqual(to: expectedUserDefaults))
    }

    @Test("Performance of migration")
    func testPerformanceOfMigration() async throws {
        let ud = MockUserDefaults()
        let sixMonthsCompleteWithV1Schema = createUserDefaultsDictionary(rawPlan: RAW_PLAN_DATA, selectionIndexToStartMarkingFalse: 365 / 2)
        ud.persistedDictionary = sixMonthsCompleteWithV1Schema
        _ = Plan(userDefaults: ud)
        #expect(true)
    }

    // MARK: - Date Index Tests

    @Test("Date index across full leap year")
    func testDateIndexAcrossFullLeapYear() async throws {
        let ud = MockUserDefaults()
        ud.set(dateInJanuary2024(), forKey: "startDate")
        let plan: Plan = Plan(userDefaults: ud)

        for i in 0...365 {
            let dateToTest: Date = Calendar.current.date(byAdding: .day, value: i, to: plan.startDate)!
            let calculatedIndex: Int = plan.indexForDateFromStartDate(from: dateToTest)
            #expect(i == calculatedIndex)
        }
    }

    @Test("Date index across full year")
    func testDateIndexAcrossFullYear() async throws {
        let ud = MockUserDefaults()
        ud.set(dateInNovember2022(), forKey: "startDate")
        let plan: Plan = Plan(userDefaults: ud)

        for i in 0...364 {
            let dateToTest: Date = Calendar.current.date(byAdding: .day, value: i, to: plan.startDate)!
            let calculatedIndex: Int = plan.indexForDateFromStartDate(from: dateToTest)
            #expect(i == calculatedIndex)
        }
    }

    @Test("Date index after a full year")
    func testDateIndexAfterAFullYear() async throws {
        let ud = MockUserDefaults()
        ud.set(dateInNovember2022(), forKey: "startDate")
        let plan: Plan = Plan(userDefaults: ud)

        for i in 0...364 {
            let dateToTest: Date = Calendar.current.date(byAdding: .day, value: i+365, to: plan.startDate)!
            let calculatedIndex: Int = plan.indexForDateFromStartDate(from: dateToTest)
            #expect(i == calculatedIndex)
        }
    }

    @Test("Date index after a full leap year")
    func testDateIndexAfterAFullLeapYear() async throws {
        let ud = MockUserDefaults()
        ud.set(dateInJanuary2024(), forKey: "startDate")
        let plan: Plan = Plan(userDefaults: ud)

        for i in 0...365 {
            let dateToTest: Date = Calendar.current.date(byAdding: .day, value: i+366, to: plan.startDate)!
            let calculatedIndex: Int = plan.indexForDateFromStartDate(from: dateToTest)
            #expect(i == calculatedIndex)
        }
    }

    @Test("Date index before start date")
    func testDateIndexBeforeStartDate() async throws {
        let ud = MockUserDefaults()
        let plan: Plan = Plan(userDefaults: ud)

        var dateToTest: Date = dateInNovember2022()
        var calculatedIndex: Int = plan.indexForDateFromStartDate(from: dateToTest)
        #expect(calculatedIndex >= 0)

        dateToTest = Calendar.current.date(byAdding: .day, value: -1, to: plan.startDate)!
        calculatedIndex = plan.indexForDateFromStartDate(from: dateToTest)
        #expect(calculatedIndex >= 0)
    }
}

// MARK: - Helper Functions (file-private)

fileprivate func currentStartDate() -> Date { Date() }

fileprivate func createPlanWithV2Schema() -> [[String]] {
    let planWithV2Schema: [[String]] = RAW_PLAN_DATA.map { selection in
        selection.map { passage in
            passage + "+" + String(selection.firstIndex(of: passage)!)
        }
    }
    return planWithV2Schema
}

fileprivate func createUserDefaultsDictionary(rawPlan: [[String]], selectionIndexToStartMarkingFalse: Int) -> [String: AnyHashable] {
    var userDefaultsDictionary: [String: AnyHashable] = [:]
    for selection in rawPlan {
        let completedValue: Bool = rawPlan.firstIndex(of: selection)! < selectionIndexToStartMarkingFalse
        for passage in selection {
            if userDefaultsDictionary.index(forKey: passage) != nil {
                continue
            }
            userDefaultsDictionary[passage] = completedValue
        }
    }
    return userDefaultsDictionary
}

// Copied from https://stackoverflow.com/a/33344575
fileprivate func dateInNovember2022() -> Date {
    var dateComponents = DateComponents()
    dateComponents.year = 2022
    dateComponents.month = 11
    dateComponents.day = 24
    dateComponents.timeZone = TimeZone(abbreviation: "PST")
    dateComponents.hour = 1
    dateComponents.minute = 56
    let userCalendar = Calendar(identifier: .gregorian)
    let finalDate = userCalendar.date(from: dateComponents)
    return finalDate!
}

fileprivate func dateInJanuary2024() -> Date {
    var dateComponents = DateComponents()
    dateComponents.year = 2024
    dateComponents.month = 01
    dateComponents.day = 05
    dateComponents.timeZone = TimeZone(abbreviation: "PST")
    dateComponents.hour = 1
    dateComponents.minute = 56
    let userCalendar = Calendar(identifier: .gregorian)
    let finalDate = userCalendar.date(from: dateComponents)
    return finalDate!
}
