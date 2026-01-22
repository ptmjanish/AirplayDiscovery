//
//  TokenStore.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation
import Security

final class TokenStore {
    
    static let shared = TokenStore()
    private init() {}
    
    private let service = "com.ptmjanish.AirplayFinder.auth"
    private let account = "accessToken"
    
    func save(token: String) {
        deleteToken()
        
        let data = Data(token.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save failed")
        }
    }
    
    func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
                let data = item as? Data,
              let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return token
    }
    
    func deleteToken() {
        
    }
    
    var isLoggedIn: Bool {
        return loadToken() != nil
    }
    
    func clearAllIfFirstLaunch() {
        let key = "hasLaunchedBefore"
        let defaults = UserDefaults.standard

        let launchedBefore = defaults.bool(forKey: key)

        if !launchedBefore {
            nukeKeychain()
            defaults.set(true, forKey: key)
            defaults.synchronize()
        }
    }
    
    func nukeKeychain() {

        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]

        for itemClass in secItemClasses {
            let query: [String: Any] = [
                kSecClass as String: itemClass
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
}
