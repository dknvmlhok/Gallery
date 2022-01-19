//
//  HomeServiceError.swift
//  Gallery
//
//  Created by Dominik Kohlman on 18.01.2022.
//

import Foundation

enum HomeServiceError: Error, LocalizedError {
    case selfIsNil
    case photoIsNil
    case decodingFailed(DecodingError)
    case dataServiceError(DataServiceError)
    case unknownError(Error)

    var errorDescription: String {
        switch self {
        case .selfIsNil:
            return "Self is nil"
        case .photoIsNil:
            return "Photo is nil"
        case .decodingFailed(let error):
            return "Decoding failed: \(String(describing: error))"
        case .dataServiceError(let error):
            return "Data service error: \(error.errorDescription)"
        case .unknownError(let error):
            return "Unknown error: \(String(describing: error))"
        }
    }
}
