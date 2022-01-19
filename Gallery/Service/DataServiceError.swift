//
//  DataServiceError.swift
//  Gallery
//
//  Created by Dominik Kohlman on 18.01.2022.
//

import Foundation
import URLCache

enum DataServiceError: Error, LocalizedError {
    case selfIsNil
    case invalidURL
    case dataIsEmpty
    case cacheError(URLCacheManagerError)
    case downloadingDataFailed(Error)

    var errorDescription: String {
        switch self {
        case .selfIsNil:
            return "Self is nil"
        case .invalidURL:
            return "Invalid url"
        case .dataIsEmpty:
            return "Data is empty"
        case .cacheError(let error):
            return "Cache error: \(error.errorDescription)"
        case .downloadingDataFailed(let error):
            return "Downloading data failed: \(String(describing: error))"
        }
    }
}
