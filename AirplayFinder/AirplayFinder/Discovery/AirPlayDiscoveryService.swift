//
//  AirPlayDiscoveryService.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation

@MainActor
final class AirPlayDiscoveryService: NSObject {
    
    private let browser = NetServiceBrowser()
    private var resolving = Set<NetService>()
    private var discovered = Set<ResolvedService>()
    
    var onUpdate: (([ResolvedService]) -> Void)?
    var onFinished: (([ResolvedService]) -> Void)?
    
    private var finishTimer: Timer?
    
    override init() {
        super.init()
        browser.delegate = self
    }
    
    
    func startScan(timeOut: TimeInterval = 6.0) {
        stopScan()
        
        discovered.removeAll()
        resolving.removeAll()
        
        browser.searchForServices(ofType: "_airplay._tcp.", inDomain: "")
        
        finishTimer = Timer.scheduledTimer(withTimeInterval: timeOut, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.stopScan()
                self.onFinished?(Array(self.discovered).sorted { $0.name < $1.name })
            }
        })
    }
    
    func stopScan() {
        finishTimer?.invalidate()
        finishTimer = nil
        browser.stop()
        resolving.removeAll()
    }
}


extension AirPlayDiscoveryService: NetServiceBrowserDelegate {
    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        service.delegate = self
        resolving.insert(service)
        service.resolve(withTimeout: 4.0)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        
    }
}


extension AirPlayDiscoveryService: NetServiceDelegate {
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        defer {
            resolving.remove(sender)
        }
        
        guard let addresses = sender.addresses else {return}
        
        if let (ip, port) = Self.extractIPAndPort(from: addresses) {
            let item = ResolvedService(name: sender.name, ipAddress: ip, port: port)
            discovered.insert(item)
            
            onUpdate?(Array(self.discovered).sorted { $0.name < $1.name })
        }
        
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        resolving.remove(sender)
    }
    
    
    // MARK: - Address parsing
    private static func extractIPAndPort(from addresses: [Data]) -> (String, Int)? {
        for data in addresses {
            var storage = sockaddr_storage()
            (data as NSData).getBytes(&storage, length: min(data.count, MemoryLayout<sockaddr_storage>.size))
            
            switch Int32(storage.ss_family) {
            case AF_INET:
                var addr = unsafeBitCast(storage, to: sockaddr_in.self)
                var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                let ipCString = inet_ntop(AF_INET, &addr.sin_port, &buffer, socklen_t(INET_ADDRSTRLEN))
                let port = Int(UInt16(bigEndian: addr.sin_port))
                if let ipCString, let ip = String(validatingUTF8: ipCString) {
                    return (ip, port)
                }
                
            case AF_INET6:
                var addr = unsafeBitCast(storage, to: sockaddr_in6.self)
                var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                let ipCString = inet_ntop(AF_INET6, &addr.sin6_addr, &buffer, socklen_t(INET6_ADDRSTRLEN))
                let port = Int(UInt16(bigEndian: addr.sin6_port))
                if let ipCString, let ip = String(validatingUTF8: ipCString) {
                    return (ip, port)
                }
                
            default:
                continue
            }
        }
        return nil
    }
}
