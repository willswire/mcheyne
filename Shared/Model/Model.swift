//
//  Model.swift
//  mcheyne-plan
//
//  Created by Will Walker on 7/19/21.
//

import Foundation

class Model: ObservableObject {
    private let readings: Dictionary = [1: ["Genesis 1", "Matthew 1", "Ezra 1", "Acts 1"]]
    
    func getReadings() -> Dictionary<Int, [String]> {
        return self.readings
    }
}
