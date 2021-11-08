// API+YouTubeRSSUtils.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import Alamofire


extension API {
    
    public func fetchGeneralVideoRSSFeed(
        from feedURLPath: String,
        then completionHandler: @escaping RSSFeedFetchCompletionHandler
    ) {
        guard let request = createRequest(
            feedURLPath,
            bodyParams: nil,
            method: "GET"
        ) else {
            completionHandler(.failure(.failedToCreateRequest(urlPath: feedURLPath)))
            return
        }
        
        
        AF.request(request).responseData { response in
            guard let data = response.data else {
                completionHandler(.failure(.unexpectedResponseData))
                return
            }
            
            completionHandler(.success(data))
        }
    }
    
    
    public func fetchGeneralVideoRSSFeed(
        for videoFeed: VideoFeed,
        then completionHandler: @escaping ((Result<[Video], Error>) -> Void)
    ) {
        guard let urlPath = videoFeed.feedURL?.absoluteString else {
            preconditionFailure()
        }
        
        fetchGeneralVideoRSSFeed(
            from: urlPath,
            then: { result in
                switch result {
                case .success(let data):
                    let parsingResult = GeneralVideoFeedXMLParser.parseFeedItems(from: data)
                    
                    switch parsingResult {
                    case .success(let videoEpisodes):
                        completionHandler(.success(videoEpisodes))
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        )
    }
}