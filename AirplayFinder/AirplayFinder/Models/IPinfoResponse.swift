//
//  IPinfoResponse.swift
//  AirplayFinder
//
//  Created by Mohammed Janish on 22/01/26.
//

import Foundation

struct IPinfoResponse: Decodable {
    let ip: String?
    let city: String?
    let region: String?
    let country: String?
    let loc: String?
    let org: String?
    let timezone: String?
    let hostname: String?
}
