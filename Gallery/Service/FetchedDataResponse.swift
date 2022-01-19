//
//  FetchedDataResponse.swift
//  Gallery
//
//  Created by Dominik Kohlman on 18.01.2022.
//

import Foundation

struct FetchedDataResponse: Hashable {
    let data: Data
    let source: DataSource

    enum DataSource: String {
        case cache
        case server
    }
}
