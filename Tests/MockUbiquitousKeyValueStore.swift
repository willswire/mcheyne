//
//  MockUbiquitousKeyValueStore.swift
//  mcheyne-plan-tests
//
//  Created by Felipe Salazar on 27.08.25.
//

import Foundation

class MockUbiquitousKeyValueStore: NSUbiquitousKeyValueStore {
    var persistedDictionary: Dictionary<String, Any> = [:]
    var synchronizeCallCount = 0
    
    override func set(_ value: Any?, forKey aKey: String) {
        persistedDictionary[aKey] = value
    }
    
    override func setValue(_ value: Any?, forKey aKey: String) {
        persistedDictionary[aKey] = value
    }
    
    override func bool(forKey aKey: String) -> Bool {
        return persistedDictionary[aKey] as? Bool ?? false
    }
    
    override func object(forKey aKey: String) -> Any? {
        return persistedDictionary[aKey]
    }
    
    override func data(forKey aKey: String) -> Data? {
        return persistedDictionary[aKey] as? Data
    }
    
    override func removeObject(forKey aKey: String) {
        persistedDictionary.removeValue(forKey: aKey)
    }
    
    override func synchronize() -> Bool {
        synchronizeCallCount += 1
        return true
    }
    
    func reset() {
        persistedDictionary.removeAll()
        synchronizeCallCount = 0
    }
}
