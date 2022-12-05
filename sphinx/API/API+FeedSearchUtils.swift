//
//  APIPodcastExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import CryptoKit
import SwiftyJSON


extension API {
    
    public func searchForFeeds(
        with type: FeedType,
        matching queryString: String,
        then completionHandler: @escaping FeedSearchCompletionHandler
    ) {
        
        let route = (type == FeedType.Podcast) ? "search_podcasts" : "search_youtube"
        let urlPath = "\(API.kTribesServerBaseURL)/\(route)"
        
        var urlComponents = URLComponents(string: urlPath)!
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: queryString)
        ]

        guard let urlString = urlComponents.url?.absoluteString else {
            completionHandler(.failure(.failedToCreateRequestURL))
            return
        }

        guard let request = createRequest(
            urlString,
            bodyParams: nil,
            method: "GET"
        ) else {
            completionHandler(.failure(.failedToCreateRequest(urlPath: urlPath)))
            return
        }

        podcastSearchRequest?.cancel()
        
        podcastSearchRequest = AF.request(request).responseJSON { response in
            switch response.result {
            case .success(let data):
                var results = [FeedSearchResult]()
                
                if let itemsArray = data as? NSArray {
                    itemsArray.forEach {
                        results.append(
                            FeedSearchResult.convertFrom(
                                searchResult: JSON($0),
                                type: type
                            )
                        )
                    }
                }
                
                completionHandler(.success(results))
            case .failure(let error):
                completionHandler(.failure(.networkError(error)))
            }
        }
    }
}
