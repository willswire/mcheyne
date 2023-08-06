//
//  MockUserDefaults.swift
//  mcheyne-plan-tests
//
//  Created by Andrew Burks on 7/22/23.
//

import Foundation

class MockUserDefaults: UserDefaults {
    var persistedDictionary: Dictionary<String, Any> = [:]
    
    override func set(_ value: Any?, forKey defaultName: String) {
        self.persistedDictionary[defaultName] = value
    }
    
    override func bool(forKey defaultName: String) -> Bool {
        var returnValue: Bool = false
        
        let value: NSNumber? = self.persistedDictionary[defaultName] as? NSNumber
        if let value {
            returnValue = value.boolValue
        }
        
        return returnValue
    }
    
    override func object(forKey defaultName: String) -> Any? {
        var returnValue: Any?
        
        if( persistedDictionary.keys.contains(defaultName) ) {
            returnValue = persistedDictionary[defaultName]
        }
        
        return returnValue
    }
    
    override func removeObject(forKey defaultName: String) {
        persistedDictionary.removeValue(forKey: defaultName)
    }
    
    override func dictionaryRepresentation() -> [String : Any] {
        return persistedDictionary
    }
}
