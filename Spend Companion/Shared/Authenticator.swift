//
//  Authenticator.swift
//  Spend Companion
//
//  Created by Mohamed Hashem on 10/23/20.
//

import UIKit
import LocalAuthentication

class Authenticator {
    
    
    static func authenticate(completion: @escaping (Bool, Error?) -> Void) {
        var biometricError: NSError?

        if LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &biometricError) {
            let reason = "Required to access the app"
            LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { (success, biometricError) in
                DispatchQueue.main.async {
                    if success {
                        completion(success, nil)
                    } else {
                        completion(success, biometricError)
                    }
                }
            }
        }
    }
    
    
}



