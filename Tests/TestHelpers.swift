//
//  TestHelpers.swift
//  The M'Cheyne Plan
//
//  Created by Will Walker on 1/4/26.
//

import Foundation

func isICloudAvailable() -> Bool {
    return FileManager.default.ubiquityIdentityToken != nil
}

extension Plan {
    func testHandleICloudSync(notification: Notification) {
        self.handleICloudSync(notification: notification)
    }
}
