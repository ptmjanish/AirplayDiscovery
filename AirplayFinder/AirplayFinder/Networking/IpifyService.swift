//
//  IpifyService.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation

enum IpifyService {
    static func fetchPublicIP() async throws -> String {
        let url = URL(string: "https://api.ipify.org?format=json")!
        let (data, resp) = try await URLSession.shared.data(from: url)
        
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "IPifyService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad response from ipify"])
        }
        
        let decoded = try JSONDecoder().decode(IpifyResponse.self, from: data)
        return decoded.ip
    }
}
