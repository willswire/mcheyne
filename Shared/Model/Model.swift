//
//  Model.swift
//  mcheyne-plan
//
//  Created by Will Walker on 7/19/21.
//

import Foundation

class Model: ObservableObject {
    private let readings: Dictionary = DATA
    
    func getReadings() -> Dictionary<Int, [String]> {
        return self.readings
    }
    
    func getReadingsFor(_ date: Date = Date()) -> [String] {
        let noReadings = ["No reading", "No reading", "No reading", "No reading"]
        let cal = Calendar.current
        guard let day = cal.ordinality(of: .day, in: .year, for: date) else { return noReadings }
        return self.readings[day] ?? noReadings
    }
}
