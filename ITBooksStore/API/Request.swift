//
//  Request.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import Foundation



struct Request {
    static let API_URL: String = "https://api.unsplash.com/photos"
    static let API_SEARCH_URL: String = "https://api.unsplash.com/search/photos"
    static let API_KEY: String = "yyHAzdGjqPFqdUDTebz2aae4T8GCC1rZPa2536j0OVo"

    static let per_page: Int = 30

    static func getPhotos(query: String = "", pageIndex: Int, completion: @escaping ([String:Any]?, Error?) -> Void) {
        var urlComponent: URLComponents?
        if query.isValid {
            urlComponent = URLComponents(string: "\(API_SEARCH_URL)")
        }
        else {
            urlComponent = URLComponents(string: "\(API_URL)")
        }

        urlComponent?.queryItems = [
            URLQueryItem(name: "page", value: "\(pageIndex)"),
            URLQueryItem(name: "per_page", value: "\(per_page)"),
            URLQueryItem(name: "client_id", value: API_KEY)
        ]

        if query.isValid {
            urlComponent?.queryItems?.append(URLQueryItem(name: "query", value: query))
        }

        guard let url = urlComponent?.url else {
            assertionFailure("URL Failure")
            return
        }
//        print(url)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = TimeInterval(10)

        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }


            if let json = try? JSONSerialization.jsonObject(with: data) {
                if let jsonArray = json as? [[String: Any]] {
//                    print("json is array", jsonArray)
                    let jsonDictionary = ["dataList": jsonArray]
                    completion(jsonDictionary, error)
                }
                else if let jsonDictionary  = json as? [String: Any] {
//                    print("json is jsonDictionary ", jsonDictionary)
                    completion(jsonDictionary, error)
                }
            }

        }.resume()
    }


}
