//
//  HomeViewController.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private let store = DeviceStore()
    private var devices: [DeviceEntity] = []
    private let discovery = AirPlayDiscoveryService()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        seedIfEmpty()
        reload()
        
        discovery.onUpdate = { [weak self] services in
            guard let self = self else { return }
            
            let now = Date()
            for s in services {
                self.store.upsert(name: s.name, ipAddress: s.ipAddress, isReachable: true, lastSeen: now)
            }
            self.reload()
        }
        
        discovery.onFinished = { [weak self] _ in
            self?.reload()
        }
        
        store.markAllUnreachable()
        discovery.startScan(timeOut: 6.0)
        reload()
    }
    
    private func reload() {
        devices = store.fetchAll()
        tableView.reloadData()
    }
    
    private func seedIfEmpty() {
        let existing = store.fetchAll()
        guard existing.isEmpty else { return }
        store.upsert(name: "Living Room TV", ipAddress: "192.168.1.10", isReachable: false)
        store.upsert(name: "Bedroom Apple TV", ipAddress: "192.168.1.11", isReachable: false)
    }
    

}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        
        let d = devices[indexPath.row]
        cell.textLabel?.text = d.name
        
        cell.detailTextLabel?.text = "\(d.ipAddress ?? "no ip address") - \(d.isReachable ? "Reachable" : "Unreachable")"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
