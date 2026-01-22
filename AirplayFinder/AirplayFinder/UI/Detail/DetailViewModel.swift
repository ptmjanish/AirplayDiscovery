//
//  DetailViewModel.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation

@MainActor
final class DetailViewModel {
    private(set) var publicIP: String?
    private(set) var ipInfo: IPinfoResponse?
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    func load(deviceIP: String?) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1) Public IP of the current network
            publicIP = try await IpifyService.fetchPublicIP()
            
            // 2) ipinfo for the device IP (if available)
            if let deviceIP, !deviceIP.isEmpty {
                ipInfo = try await IPInfoService.fetchInfo(for: deviceIP)
            } else {
                ipInfo = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
