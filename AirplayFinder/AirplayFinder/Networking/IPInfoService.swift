//
//  IPInfoService.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation

enum IPInfoService {

    static func fetchInfo(for ip: String) async throws -> IPinfoResponse {
        let url = URL(string: "https://ipinfo.io/\(ip)/json")!
        var req = URLRequest(url: url)

        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "IPInfoService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bad response from ipinfo"])
        }

        return try JSONDecoder().decode(IPinfoResponse.self, from: data)
    }
}
