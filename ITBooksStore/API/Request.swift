//
//  Request.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import Foundation
import UIKit

struct Request {
    private static var URLCache: NSCache<NSString, AnyObject>?


    @discardableResult
    static func request(url: String, query: String = "", pageIndex: Int = -1, completion: @escaping ([String:Any]?, Error?) -> Void) -> URLSessionDataTask? {
        guard url.isValid else { return  nil }
        var urlString = url
        if query.isValid {
            urlString += "/\(query)"
        }
        if pageIndex > -1 {
            urlString += "/\(pageIndex)"
        }

        if let data = Self.URLCache?.object(forKey: urlString as NSString) as? [String: Any] {
            print("cache url: \(urlString)")
            completion(data, nil)
            return nil
        }

        let urlComponent = URLComponents(string: urlString)
        guard let url = urlComponent?.url else {
            assertionFailure("URL Failure")
            return nil
        }
        print("request \(url)")



        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = TimeInterval(10)

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) {
                var dic = [String: Any]()
                if let jsonArray = json as? [[String: Any]] {
//                    print("json is array", jsonArray)
                    dic = ["dataList": jsonArray]
                }
                else if let jsonDictionary  = json as? [String: Any] {
//                    print("json is jsonDictionary ", jsonDictionary)
                    dic = jsonDictionary
                }

                if Self.URLCache == nil {
                    Self.URLCache = NSCache<NSString, AnyObject>()
                    Self.URLCache?.countLimit = 100
                }
                Self.URLCache?.setObject(dic as AnyObject, forKey: urlString as NSString)
                completion(dic, error)

            }

        }
        task.resume()
        return task
    }
}

class ITBookListData: PKHParser {
    static let API_SEARCH_URL: String = "https://api.itbook.store/1.0/search"

    var error: String = ""
    var total: String = ""
    var page: String = ""
    var books = [ITBookListItemData]()

    static func requestSearchData(query: String, pageIndex: Int, completion: @escaping (Self) -> Void) -> URLSessionDataTask? {
        return Request.request(url: Self.API_SEARCH_URL, query: query, pageIndex: pageIndex) { requestData, error in
            guard let requestData = requestData else { return }
            Self.initAsync(map: requestData, completionHandler: { (obj: Self) in
                completion(obj)
            })
        }
    }
}

class ITBookListItemData: PKHParser {
    var title: String = ""
    var subtitle: String = ""
    var isbn13: String = ""
    var price: String = ""
    var image: String = ""
    var url: String = ""

    /// UIData
    var tempImage: UIImage?
}

class ITBookDetailData: PKHParser {
    static let API_BOOK_DETAIL_URL: String = "https://api.itbook.store/1.0/books"

    var error: String = ""
    var title: String = ""
    var subtitle: String = ""
    var authors: String = ""
    var publisher: String = ""
    var language: String = ""
    var isbn10: String = ""
    var isbn13: String = ""
    var pages: String = ""
    var year: String = ""
    var rating: String = ""
    var desc: String = ""
    var price: String = ""
    var image: String = ""
    var url: String = ""

    static func request(isbn13: String, completion: @escaping (Self) -> Void) -> URLSessionDataTask? {
        return Request.request(url: "\(Self.API_BOOK_DETAIL_URL)/\(isbn13)") { requestData, error in
            guard let requestData = requestData else { return }
            Self.initAsync(map: requestData, completionHandler: { (obj: Self) in
                completion(obj)
            })
        }
    }
}
