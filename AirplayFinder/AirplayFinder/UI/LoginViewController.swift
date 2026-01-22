//
//  LoginViewController.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import UIKit

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func fakeLoginTapped(_ sender: Any) {
        TokenStore.shared.save(token: "FAKE_TOKEN")
        let home = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "HomeViewController")
        navigationController?.setViewControllers([home], animated: true)
        
    }
    
}
