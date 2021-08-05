//
//  Request.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import Foundation
import UIKit

class Request {
    private static var URLCache: NSCache<NSString, AnyObject>?

    @discardableResult
    static func request(urlString: String, query: String = "", pageIndex: Int = -1, cache: Bool = true, completion: @escaping ([String:Any]?, Error?) -> Void) -> URLSessionDataTask? {
        guard urlString.isValid else { return  nil }
        var urlString = urlString
        if query.isValid {
            urlString += "/\(query)"
        }
        if pageIndex > -1 {
            urlString += "/\(pageIndex)"
        }

        if let data = getMemoryCaach(urlString: urlString) {
//            print("cache url: \(urlString)")
            completion(data, nil)
            return nil
        }

        let urlComponent = URLComponents(string: urlString)
        guard let url = urlComponent?.url else {
            return nil
        }
//        print("request \(url)")

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in

            if let _ = error {
//                print("iamge download error: " + error.localizedDescription + "\n")
                return
            }
            else if let response = response as? HTTPURLResponse {
                if response.statusCode == 200, let data = data, let json = try? JSONSerialization.jsonObject(with: data) {

                    var dic = [String: Any]()
                    if let jsonArray = json as? [[String: Any]] {
                        //                    print("json is array", jsonArray)
                        dic = ["dataList": jsonArray]
                    }
                    else if let jsonDictionary  = json as? [String: Any] {
                        //                    print("json is jsonDictionary ", jsonDictionary)
                        dic = jsonDictionary
                    }

                    completion(dic, error)

                    self.saveMemoryCache(urlString: urlString, dic: dic)
                }
                else {
                    print("response.statusCode: \(response.statusCode)")
                }
            }

        }
        task.resume()
        return task
    }

    static func getMemoryCaach(urlString: String?) -> [String: Any]? {
        guard let urlString = urlString, urlString.isValid else { return  nil }
        return Self.URLCache?.object(forKey: urlString as NSString) as? [String: Any]
    }

    static func saveMemoryCache(urlString: String?, dic: [String: Any]?) {
        guard let urlString = urlString, let dic = dic else { return }
        if Self.URLCache == nil {
            Self.URLCache = NSCache<NSString, AnyObject>()
            Self.URLCache?.countLimit = 100
            Self.URLCache?.totalCostLimit = 50 * 1024 * 1024;
        }
        if Self.URLCache?.object(forKey: urlString as NSString) == nil {
            Self.URLCache?.setObject(dic as AnyObject, forKey: urlString as NSString)
        }
    }

    static func momoryCacheClear() {
        Self.URLCache?.removeAllObjects()
    }
}

class ITBookListData: PKHParser {
    static let API_SEARCH_URL: String = "https://api.itbook.store/1.0/search"

    var error: String = ""
    var total: String = ""
    var page: String = ""
    var books = [ITBookListItemData]()

    static func requestSearchData(query: String, pageIndex: Int, completion: @escaping (Self) -> Void) -> URLSessionDataTask? {
        return Request.request(urlString: Self.API_SEARCH_URL, query: query, pageIndex: pageIndex) { requestData, error in
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
        return Request.request(urlString: "\(Self.API_BOOK_DETAIL_URL)/\(isbn13)") { requestData, error in
            guard let requestData = requestData else { return }
            Self.initAsync(map: requestData, completionHandler: { (obj: Self) in
                completion(obj)
            })
        }
    }
}
