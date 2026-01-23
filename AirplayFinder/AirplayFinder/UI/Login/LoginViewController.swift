//
//  LoginViewController.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import UIKit

class LoginViewController: UIViewController {
    
    private var oauthState: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func loginTapped(_ sender: Any) {
        Task { @MainActor in
            let status = await Reachability.shared.waitForInitialStatus(timeout: 0.8)
            print("[Login] reachability:", status)
            guard status.isReachable else {
                print("Offline. Cannot start login")
                return
            }
            startGitHubLoginFlow()
        }
    }
    
    @MainActor
    private func startGitHubLoginFlow() {
        let authURL = buildGitHubAuthorizeURL()
        LoginManager.shared().startLogin(from: self,
                                         authURL: authURL,
                                         callbackScheme: AuthConstants.redirectScheme) {[weak self] code, error in
            guard let self else {return}
            if let error {
                print("Auth session failed:", error)
                return
            }
            
            guard let code, !code.isEmpty else {
                print("Missing auth code")
                return
            }
            
            LoginManager.shared().exchangeCode(forGitHubToken: code,
                                               tokenURL: AuthConstants.tokenUrl,
                                               clientId: AuthConstants.clientId,
                                               clientSecret: AuthConstants.clientSecret,
                                               redirectURI: AuthConstants.redirectUrl) { token, error in
                DispatchQueue.main.async {
                    if let error {
                        print("Token exchange failed:", error)
                        return
                    }
                    
                    guard let token, !token.isEmpty else {
                        print("Missing access token")
                        return
                    }
                    
                    TokenStore.shared.save(token: token)
                    print("Token saved")
                    
                    let home = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "HomeViewController")
                    self.navigationController?.setViewControllers([home], animated: true)
                }
            }
        }
    }
    
    
    
    //MARK: GitHub authorize URL
    private func buildGitHubAuthorizeURL() -> URL {
        var comps = URLComponents(url: AuthConstants.authorizeUrl, resolvingAgainstBaseURL: false)!
        
        let state = UUID().uuidString
        oauthState = state
        
        comps.queryItems = [
            URLQueryItem(name: "client_id", value: AuthConstants.clientId),
            URLQueryItem(name: "redirect_uri", value: AuthConstants.redirectUrl),
            URLQueryItem(name: "scope", value: "user:email"),
            URLQueryItem(name: "state", value: state)
            ]
        return comps.url!
    }
    
}
