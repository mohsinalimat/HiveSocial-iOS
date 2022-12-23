//
//  AuthorizationManager.swift
//  HIVE
//
//  Created by Daniel Pratt on 9/20/19.
//  Copyright © 2019 Kassy Pop. All rights reserved.
//

import Foundation
import StoreKit
import Firebase

class RequestCapabilitiesOperation: AsyncOperation {
    var capabilities: SKCloudServiceCapability?
    override func main() {
        SKCloudServiceController().requestCapabilities { result, error in
            self.capabilities = result
            self.state = .finished
        }
    }
}

class DownloadDeveloperTokenOperation: AsyncOperation {
    var developerToken: String?
    override func main() {
//        self.developerToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IkNIQkhRQ1pYM0oifQ.eyJpc3MiOiJKQUw3R0g1R1JHIiwiaWF0IjoxNjA2Nzk2NjY5LCJleHAiOjE2MjI1NjEwNjl9.rg3Wr1uGv2-NTsvQb3tej0rjCNLdYWC9kZEK5PEjjk_cwosXQp55SBXZkT7Q8e-9M2Vn0GcycP5sOamRttorkw"
//        self.developerToken = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IkNIQkhRQ1pYM0oifQ.eyJpc3MiOiJKQUw3R0g1R1JHIiwiaWF0IjoxNjEzMDExNDI2LCJleHAiOjE2MTMwNTQ2MjZ9.rqGcEF0zxEU6kNMgQnZyjKHNh_lDd454R6BtV-wkYbj1wDK97-FqaZ6PjiKfOdckbvLV61T4jOi2iMWxwGkeCQ"
//        self.state = .finished
        FAMAPI_REF
            .document("valid")
            .getDocument { (val, err) in
                print("================== Music API Developer Token Retrieved ==================")
                if let error = err{
                    print(error.localizedDescription)
                    return
                }

                if let data = val?.data(), let token = data["key"] as? String{
                    self.developerToken = token
                    self.state = .finished
                }
            }
    }
}

class RequestCountryCodeOperation: AsyncOperation {
    var countryCode: String?
    override func main() {
        SKCloudServiceController().requestStorefrontCountryCode { result, error in
            self.countryCode = result
            self.state = .finished
        }
    }
}

class DownloadUserTokenOperation: AsyncOperation {
    var userToken: String?
    private let userTokenKey = "userTokenKey"
    
    override func main() {
        if let cachedToken = UserDefaults.standard.string(forKey: userTokenKey) {
            self.userToken = cachedToken
            self.state = .finished
        } else {
            guard let developerToken = AuthorizationManager.downloadDeveloperTokenOperation.developerToken else {
                self.state = .finished
                return
            }
            SKCloudServiceController().requestUserToken(forDeveloperToken: developerToken) { result, error in
                guard error == nil else {
                    print("Error getting user token: \(error!.localizedDescription)")
                    self.state = .finished
                    return
                }
                self.userToken = result
                UserDefaults.standard.set(result, forKey: self.userTokenKey)
                self.state = .finished
            }
        }
    }
}

struct MusicKitTokens {
    private var developerToken: String? = nil
    private var countryCode: String? = nil
    private var userToken: String? = nil
    
    var isLoaded: Bool {
        return developerToken != nil && countryCode != nil && userToken != nil
    }
    
    mutating func setTokens(dev: String, country: String, user: String) {
        developerToken = dev
        countryCode = country
        userToken = user
    }
    
    func getTokens() -> (developer: String, country: String, user: String)? {
        if isLoaded, let dev = developerToken, let country = countryCode, let user = userToken {
            return (dev, country, user)
        } else { return nil }
    }
    
    static var shared = MusicKitTokens()
}

class AuthorizationManager {
    
    var isAuthorized: Bool = false
    
    static var shared = AuthorizationManager()
    
    static func authorize(completionIfAuthorized authorizedCompletion: @escaping () -> Void, ifUnauthorized unauthorizedCompletion: @escaping () -> Void) {
        SKCloudServiceController.requestAuthorization { authorizationStatus in
            print("~>Got status: \(authorizationStatus)")
            switch authorizationStatus {
            case .authorized:
                AuthorizationManager.shared.isAuthorized = true
                DispatchQueue.main.async {
                    authorizedCompletion()
                }
            case .restricted, .denied:
                DispatchQueue.main.async {
                    unauthorizedCompletion()
                }
            default:
                DispatchQueue.main.async {
                    unauthorizedCompletion()
                }
                break
            }
        }
    }
    
    private static let capabilitiesOperation = RequestCapabilitiesOperation()
    
    private static let capabilitesQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.addOperation(capabilitiesOperation)
        let subscribeOperation = BlockOperation {
            guard let capabilities = capabilitiesOperation.capabilities else { return }
            if capabilities.contains(.musicCatalogPlayback) == false, capabilities.contains(.musicCatalogSubscriptionEligible) {
                DispatchQueue.main.async {
                    let signupController = SKCloudServiceSetupViewController()
                    signupController.load(options: [.action: SKCloudServiceSetupAction.subscribe]) { isLoaded, error in
                        guard error == nil else {
                            print("Error loading subscription view: \(error!.localizedDescription)")
                            return
                        }
                        if isLoaded {
                            signupController.show(animated: true)
                        }
                    }
                }
            }
        }
        subscribeOperation.addDependency(capabilitiesOperation)
        queue.addOperation(subscribeOperation)
        return queue
    }()
    
    static func withCapabilities(completion: @escaping (SKCloudServiceCapability) -> Void) {
        let operation = BlockOperation {
            guard let capabilities = capabilitiesOperation.capabilities else { return }
            completion(capabilities)
        }
        operation.addDependency(capabilitiesOperation)
        capabilitesQueue.addOperation(operation)
    }
    
    fileprivate static let downloadDeveloperTokenOperation = DownloadDeveloperTokenOperation()
    private static let requestCountryCodeOperation = RequestCountryCodeOperation()
    
    private static let musicAPIQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.addOperation(downloadDeveloperTokenOperation)
        queue.addOperation(requestCountryCodeOperation)
        return queue
    }()
    
    static func withAPIData(completion: @escaping (String, String) -> Void) {
        if MusicKitTokens.shared.isLoaded, let tokens = MusicKitTokens.shared.getTokens() {
            completion(tokens.developer, tokens.country)
            return
        }
        
        let operation = BlockOperation {
            guard let developerToken = downloadDeveloperTokenOperation.developerToken, let countryCode = requestCountryCodeOperation.countryCode else { return }
            MusicKitTokens.shared.setTokens(dev: developerToken, country: countryCode, user: "")
            completion(developerToken, countryCode)
        }
        operation.addDependency(downloadDeveloperTokenOperation)
        operation.addDependency(requestCountryCodeOperation)
        musicAPIQueue.addOperation(operation)
    }
    
    private static let downloadUserTokenOperation = DownloadUserTokenOperation()
    private static let musicUserAPIQueue: OperationQueue = {
        let queue = OperationQueue()
        downloadUserTokenOperation.addDependency(downloadDeveloperTokenOperation)
        queue.addOperation(downloadUserTokenOperation)
        return queue
    }()
    
    static func withUserAPIData(completion: @escaping (String, String, String) -> Void) {
        if MusicKitTokens.shared.isLoaded, let tokens = MusicKitTokens.shared.getTokens(), !tokens.user.isEmpty {
            completion(tokens.developer, tokens.country, tokens.user)
            return
        }
        let operation = BlockOperation {
            guard let developerToken = downloadDeveloperTokenOperation.developerToken, let countryCode = requestCountryCodeOperation.countryCode, let userToken = downloadUserTokenOperation.userToken else { return }
            MusicKitTokens.shared.setTokens(dev: developerToken, country: countryCode, user: userToken)
            completion(developerToken, countryCode, userToken)
        }
        operation.addDependency(downloadUserTokenOperation)
        musicUserAPIQueue.addOperation(operation)
    }
}
