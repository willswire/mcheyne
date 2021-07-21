//
//  Model.swift
//  mcheyne-plan
//
//  Created by Will Walker on 7/19/21.
//

import Foundation

class Model: ObservableObject {
    private let selections = ReadingSelections()
    
    func getSelections() -> ReadingSelections {
        return self.selections
    }
}

extension String: Identifiable {
    public var id: UUID {
        UUID(uuidString: self) ?? UUID()
    }
}
