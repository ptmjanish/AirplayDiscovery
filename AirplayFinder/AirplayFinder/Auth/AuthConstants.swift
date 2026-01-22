//
//  AuthConstants.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation

enum AuthConstants {
    static let clientId = "Ov23liSoJFiVME9dayEI"
    static let clientSecret = "03c104ef2b0a8d6cb1f49ca0621ab152341d545c"
    
    static let authorizeUrl = URL(string: "https://github.com/login/oauth/authorize")!
    static let tokenUrl = URL(string: "https://github.com/login/oauth/access_token")!
    
    static let redirectScheme = "airplayfinder"
    static let redirectUrl = "airplayfinder://oauth/callback"
    
    static let scope = "read:user user:email"
}
