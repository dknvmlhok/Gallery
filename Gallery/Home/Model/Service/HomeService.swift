//
//  HomeService.swift
//  Gallery
//
//  Created by Dominik Kohlman on 10.01.2022.
//

import Combine
import Foundation

final class HomeService {

    // MARK: - Properties

    private let dataService = DataService()

    // MARK: - Methods

    var mediumPhotos: AnyPublisher<[FetchedDataResponse], HomeServiceError> {
        photoSources
            .flatMap { sourcesArray -> AnyPublisher<Sources, HomeServiceError> in
                Publishers.Sequence(sequence: sourcesArray)
                    .eraseToAnyPublisher()
            }
            .flatMap { [weak self] sources -> AnyPublisher<FetchedDataResponse, HomeServiceError> in

                guard let self = self else {
                    return Fail(error: .selfIsNil)
                        .eraseToAnyPublisher()
                }
                guard let photoUrl = sources.medium else {
                    return Fail(error: .photoIsNil)
                        .eraseToAnyPublisher()
                }

                return self.dataService.fetchData(for: photoUrl)
                    .mapError { HomeServiceError.dataServiceError($0) }
                    .eraseToAnyPublisher()
            }
            .collect()
            .eraseToAnyPublisher()
    }

    func clearCache() -> AnyPublisher<Void, HomeServiceError> {
        dataService.clearAllCachedData()
            .mapError { .dataServiceError($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private Methods

private extension HomeService {

    var photoSources: AnyPublisher<[Sources], HomeServiceError> {
        dataService
            .fetchData(for: "https://api.pexels.com/v1/curated?per_page=80")
            .mapError { HomeServiceError.dataServiceError($0) }
            .flatMap { Just($0.data) }
            .decode(type: PhotosResponse.self, decoder: JSONDecoder())
            .mapError { error in
                guard let decodingError = error as? DecodingError else {
                    return .unknownError(error)
                }
                return .decodingFailed(decodingError)
            }
            .compactMap { $0.photos?.compactMap { $0.src } }
            .eraseToAnyPublisher()
    }
}
