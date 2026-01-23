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
        
//        seedIfEmpty()
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
            self?.updateEmptyState()
        }
    }
    
    private func updateEmptyState() {
        let count = fetchedResultsController.fetchedObjects?.count ?? 0

        if count == 0 {
            let label = UILabel()
            label.text = "No AirPlay devices found.\n\nTap Rescan to try again."
            label.textAlignment = .center
            label.numberOfLines = 0
            label.textColor = .secondaryLabel
            label.font = .systemFont(ofSize: 16, weight: .regular)
            label.translatesAutoresizingMaskIntoConstraints = false

            let container = UIView()
            container.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 24),
                label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -24)
            ])

            tableView.backgroundView = container
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }
    
    private func performFetch() {
        do {
            try fetchedResultsController.performFetch()
            tableView.reloadData()
            updateEmptyState()
        } catch {
            print("FRC performFetch failed:", error)
            updateEmptyState()
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
        
        let device = fetchedResultsController.object(at: indexPath)
        
        let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        detail.device = device
        navigationController?.pushViewController(detail, animated: true)
    }
}

//MARK: NSFetchedResultsControllerDelegate
extension HomeViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        tableView.reloadData()
        updateEmptyState()
    }
    
}
