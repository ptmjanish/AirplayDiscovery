//
//  Reachability.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation
import Network


final class Reachability {
    
    static let shared = Reachability()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Network.Reachability.Monitor")
    
    private(set) var isReachable: Bool = false
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isReachable = path.status == .satisfied
            print("Reachability changed:", self?.isReachable == true ? "Online" : "Offline")
        }
        monitor.start(queue: queue)
    }
}
