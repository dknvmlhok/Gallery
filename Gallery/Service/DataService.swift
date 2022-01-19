//
//  DataService.swift
//  Gallery
//
//  Created by Dominik Kohlman on 06.01.2022.
//

import Combine
import Foundation
import URLCache

final class DataService {

    // MARK: - Properties

    private let urlCacheManager = URLCacheManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Methods

    func fetchData(for urlString: String) -> AnyPublisher<FetchedDataResponse, DataServiceError> {

        guard let url = URL(string: urlString) else {
            return Fail(error: .invalidURL)
                .eraseToAnyPublisher()
        }

        let urlRequest = buildURLRequest(with: url)

        return dataIsCached(for: urlRequest)
            .flatMap { [weak self] dataIsCached -> AnyPublisher<FetchedDataResponse, DataServiceError> in

                guard let self = self else {
                    return Fail(error: .selfIsNil)
                        .eraseToAnyPublisher()
                }

                if dataIsCached {
                    return self.loadCachedData(for: urlRequest)
                        .flatMap {
                            Just(FetchedDataResponse(data: $0, source: .cache))
                                .setFailureType(to: DataServiceError.self)
                        }
                        .eraseToAnyPublisher()
                } else {
                    return self.downloadData(for: urlRequest)
                        .flatMap {
                            Just(FetchedDataResponse(data: $0, source: .server))
                                .setFailureType(to: DataServiceError.self)
                        }
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func clearAllCachedData() -> AnyPublisher<Void, DataServiceError> {
        Deferred {
            Future { [weak self] promise in

                guard let self = self else {
                    promise(.failure(.selfIsNil))
                    return
                }

                Task {
                    await self.urlCacheManager.clearAllCachedData()
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private Methods

private extension DataService {

    func buildURLRequest(with url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("563492ad6f9170000100000149da7bd09e2649969f5751c71089040e", forHTTPHeaderField: "Authorization")

        return request
    }

    func dataIsCached(for request: URLRequest) -> AnyPublisher<Bool, DataServiceError> {
        Deferred {
            Future { [weak self] promise in

                guard let self = self else {
                    promise(.failure(.selfIsNil))
                    return
                }

                Task {
                    let output = await self.urlCacheManager.dataIsCached(for: request)
                    promise(.success(output))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func loadCachedData(for request: URLRequest) -> AnyPublisher<Data, DataServiceError> {
        Deferred {
            Future { [weak self] promise in

                guard let self = self else {
                    promise(.failure(.selfIsNil))
                    return
                }

                Task {
                    do {
                        let output = try await self.urlCacheManager.loadCachedData(for: request)
                        promise(.success(output))
                    } catch {
                        guard let error = error as? URLCacheManagerError else { return }
                        promise(.failure(.cacheError(error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    @discardableResult
    func storeDataToCache(request: URLRequest, data: Data, response: URLResponse) -> AnyPublisher<Void, DataServiceError> {
        Future { [weak self] promise in

            guard let self = self else {
                promise(.failure(.selfIsNil))
                return
            }

            Task {
                let cachedResponse = CachedURLResponse(
                    response: response,
                    data: data,
                    storagePolicy: .allowed
                )
                await self.urlCacheManager.storeDataToCache(
                    cachedResponse: cachedResponse,
                    for: request
                )

                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }

    func downloadData(for request: URLRequest) -> AnyPublisher<Data, DataServiceError> {
        URLSession.shared.dataTaskPublisher(for: request)
            .mapError { .downloadingDataFailed($0) }
            .flatMap { [weak self] (data, response) -> AnyPublisher<Data, DataServiceError> in

                guard let self = self else {
                    return Fail(error: .selfIsNil)
                        .eraseToAnyPublisher()
                }
                guard !data.isEmpty else {
                    return Fail(error: .dataIsEmpty)
                        .eraseToAnyPublisher()
                }

                self.storeDataToCache(
                    request: request,
                    data: data,
                    response: response
                )

                return Just(data)
                    .setFailureType(to: DataServiceError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
