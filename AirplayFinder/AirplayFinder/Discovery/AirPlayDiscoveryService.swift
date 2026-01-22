//
//  AirPlayDiscoveryService.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation
import Darwin

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
        
        guard let addresses = sender.addresses else {
            return
        }
        
        
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
            let result: (String, Int)? = data.withUnsafeBytes { rawBuffer in
                guard let baseAddress = rawBuffer.baseAddress else { return nil }

                let sockaddrPtr = baseAddress.assumingMemoryBound(to: sockaddr.self)

                switch Int32(sockaddrPtr.pointee.sa_family) {

                case AF_INET:
                    let addrInPtr = baseAddress.assumingMemoryBound(to: sockaddr_in.self)
                    var addr = addrInPtr.pointee

                    var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    var sinAddr = addr.sin_addr
                    guard inet_ntop(AF_INET, &sinAddr, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil else {
                        return nil
                    }

                    let ip = String(cString: buffer)
                    let port = Int(UInt16(bigEndian: addr.sin_port))
                    return (ip, port)

                case AF_INET6:
                    let addrIn6Ptr = baseAddress.assumingMemoryBound(to: sockaddr_in6.self)
                    var addr = addrIn6Ptr.pointee

                    var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                    var sin6Addr = addr.sin6_addr
                    guard inet_ntop(AF_INET6, &sin6Addr, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil else {
                        return nil
                    }

                    let ip = String(cString: buffer)
                    let port = Int(UInt16(bigEndian: addr.sin6_port))
                    return (ip, port)

                default:
                    return nil
                }
            }

            if let result { return result }
        }
        return nil
    }
}
