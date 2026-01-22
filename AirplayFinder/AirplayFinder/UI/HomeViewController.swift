//
//  HomeViewController.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import UIKit
import CoreData

class HomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private let store = DeviceStore()
    private let discovery = AirPlayDiscoveryService()
    private var didAutoScan = false
    
    
    private lazy var fetchedResultsController: NSFetchedResultsController<DeviceEntity> =  {
        let request: NSFetchRequest<DeviceEntity> = DeviceEntity.fetchRequest()
        
        request.sortDescriptors = [
            NSSortDescriptor(key: "isReachable", ascending: false),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        let frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: CoreDataStack.shared.context,
            sectionNameKeyPath: nil,
            cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNav()
        setupRefresh()
        setupDiscoveryCallBacks()
        
        seedIfEmpty()
        performFetch()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !didAutoScan else { return }
        didAutoScan = true
        rescan()
    }
    
    
    
    private func setupNav() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Rescan",
            style: .plain,
            target: self,
            action: #selector(rescanTapped)
        )
    }
    
    private func setupRefresh() {
        let r = UIRefreshControl()
        r.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = r
    }
    
    private func setupDiscoveryCallBacks() {
        discovery.onUpdate = { [weak self] services in
            guard let self else { return }
            DispatchQueue.main.async {
                let now = Date()
                for s in services {
                    self.store.upsert(
                        name: s.name,
                        ipAddress: s.ipAddress,
                        isReachable: true,
                        lastSeen: now)
                }
            }
            
        }
        
        discovery.onFinished =  { [weak self] services in
            self?.tableView.refreshControl?.endRefreshing()
        }
    }
    
    private func seedIfEmpty() {
        let existing = store.fetchAll()
        guard existing.isEmpty else { return }
        store.upsert(name: "Living Room TV", ipAddress: "192.168.1.10", isReachable: false)
        store.upsert(name: "Bedroom Apple TV", ipAddress: "192.168.1.11", isReachable: false)
        
    }
    
    private func performFetch() {
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
        } catch {
            print("FRC performFetch failed:", error)
        }
    }
    
    
    @objc private func rescanTapped() {
        rescan()
    }
    
    @objc private func pullToRefresh() {
        rescan()
    }
    
    private func rescan() {
        tableView.refreshControl?.beginRefreshing()
        store.markAllUnreachable()
        discovery.startScan(timeOut: 6.0)
    }
    

    @IBAction func logoutTapped(_ sender: Any) {
        TokenStore.shared.deleteToken()
        let login = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(identifier: "LoginViewController")
        
        navigationController?.setViewControllers([login], animated: true)
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        let device = fetchedResultsController.object(at: indexPath)
        
        
        cell.textLabel?.text = device.name
        
        let status = device.isReachable ? "Reachable" : "Unreachable"
        cell.detailTextLabel?.text = "\(device.ipAddress ?? "no ip address") - \(status)"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

//MARK: NSFetchedResultsControllerDelegate
extension HomeViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        tableView.reloadData()
    }
    
//    func controller(_ controller: NSFetchedResultsController<any NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        
//        switch type {
//        case .insert:
//            if let newIndexPath {
//                tableView.insertRows(at: [newIndexPath], with: .automatic)
//            }
//        case .delete:
//            if let indexPath {
//                tableView.deleteRows(at: [indexPath], with: .automatic)
//            }
//        case .move:
//            if let indexPath {
//                tableView.deleteRows(at: [indexPath], with: .automatic)
//            }
//            if let newIndexPath {
//                tableView.insertRows(at: [newIndexPath], with: .automatic)
//            }
//        case .update:
//            if let indexPath {
//                tableView.reloadRows(at: [indexPath], with: .automatic)
//            }
//        @unknown default:
//            tableView.reloadData()
//        }
//    }
}
