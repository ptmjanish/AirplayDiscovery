//
//  SplashViewController.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import UIKit

class SplashViewController: UIViewController {

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.startAnimating()
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        Task { @MainActor in
            await runAuthFlow()
        }
    }
    
    @MainActor
    private func runAuthFlow() async {
        // No token? no need to wait for network at all.
        guard let token = TokenStore.shared.loadToken() else {
            gotoLogin()
            return
        }
        
        // Wait for the first *real* reachability update (or short timeout)
        let status = await Reachability.shared.waitForInitialStatus(timeout: 0.8)
        print("Reachability initial status:", status)
        
        // Force logout ONLY if confirmed offline
        if !status.isReachable {
            print("Offline at launch with token → force logout")
            TokenStore.shared.deleteToken()
            gotoLogin()
            return
        }
        
        // Online + token exists → silent auth validation
        let isValid = await GitHubAPI.validateToken(token)
        if isValid {
            print("Silent auth success")
            gotoHome()
        } else {
            print("Silent auth failed → logout")
            TokenStore.shared.deleteToken()
            gotoLogin()
        }
    }
    
    private func gotoHome() {
        let home = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "HomeViewController")
        let nav = UINavigationController(rootViewController: home)
        replaceRoot(with: nav)
    }
    
    private func gotoLogin() {
        let login = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "LoginViewController")
        let nav = UINavigationController(rootViewController: login)
        replaceRoot(with: nav)
    }
    
    private func replaceRoot(with vc: UIViewController) {
        guard let window = view.window ?? UIApplication.shared.connectedScenes.compactMap({($0 as? UIWindowScene)?.keyWindow}).first else { return }
        
        window.rootViewController = vc
        UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: nil)
    }
}
