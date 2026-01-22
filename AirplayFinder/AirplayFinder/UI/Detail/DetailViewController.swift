//
//  DetailViewController.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelLocalIp: UILabel!
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var labelLastSeen: UILabel!
    @IBOutlet weak var labelPublicIP: UILabel!
    @IBOutlet weak var labelIpInfo: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var device: DeviceEntity!
    
    private let viewModel = DetailViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        renderStatic()
        renderDynamic()
        load()
    }
    
    private func renderStatic() {
        labelName.text = "Name: \(device.name ?? "-")"
        labelLocalIp.text = "Local IP: \(device.ipAddress ?? "-")"
        labelStatus.text = "Status: \(device.isReachable ? "Reachable" : "Not Reachable")"
        
        if let lastSeen = device.lastSeen {
            let s = DateFormatter.localizedString(from: lastSeen, dateStyle: .medium, timeStyle: .short)
            labelLastSeen.text = "Last Seen: \(s)"
        } else {
            labelLastSeen.text = "Last Seen: -"
        }
        
        labelPublicIP.text = "Public IP: -"
        labelIpInfo.text = "IP Info: -"
    }
    
    private func load() {
        spinner.isHidden = false
        spinner.startAnimating()
        Task {
            await viewModel.load(deviceIP: device.ipAddress)
            
            spinner.stopAnimating()
            spinner.isHidden = true
            renderDynamic()
        }
    }
    
    private func renderDynamic() {

        // Public IP
        if let publicIP = viewModel.publicIP {
            labelPublicIP.text = "Public IP: \(publicIP)"
        } else {
            labelPublicIP.text = "Public IP: -"
        }

        // ipinfo block
        if let info = viewModel.ipInfo {
            var lines: [String] = []

            if let ip = info.ip {
                lines.append("IP: \(ip)")
            }

            if let hostname = info.hostname {
                lines.append("Hostname: \(hostname)")
            }

            if let city = info.city {
                lines.append("City: \(city)")
            }

            if let region = info.region {
                lines.append("Region: \(region)")
            }

            if let country = info.country {
                lines.append("Country: \(country)")
            }

            if let org = info.org {
                lines.append("Organization: \(org)")
            }

            if let timezone = info.timezone {
                lines.append("Timezone: \(timezone)")
            }

            if let loc = info.loc {
                lines.append("Location (lat,long): \(loc)")
            }

            labelIpInfo.text = lines.isEmpty
                ? "IP Info: No information available"
                : lines.joined(separator: "\n")

        } else {
            labelIpInfo.text = "IP Info: -"
        }

        // Error override (always wins)
        if let err = viewModel.errorMessage {
            labelIpInfo.text = "Error: \(err)"
        }
    }


}
