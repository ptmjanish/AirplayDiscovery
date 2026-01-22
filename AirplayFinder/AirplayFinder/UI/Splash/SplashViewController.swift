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
        runAuthFlow()
    }
    
    private func runAuthFlow() {
        if let token = TokenStore.shared.loadToken(),
            !Reachability.shared.isReachable {
            print("Offline at launch with token -> force logout")
            TokenStore.shared.nukeKeychain()
            gotoLogin()
            return
        }
        
        guard let token = TokenStore.shared.loadToken() else {
            gotoLogin()
            return
        }
        
        Task {
            let isValid = await GitHubAPI.validateToken(token)
            await MainActor.run {
                if isValid {
                    print("Silent auth success")
                    self.gotoHome()
                }
                else {
                    print("Silent auth failed")
                    TokenStore.shared.nukeKeychain()
                    self.gotoLogin()
                }
            }
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
