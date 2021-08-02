//
//  Request.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import Foundation




struct Request {
    @discardableResult
    static func request(url: String, query: String = "", pageIndex: Int = -1, completion: @escaping ([String:Any]?, Error?) -> Void) -> URLSessionDataTask? {
        guard url.isValid else { return  nil }
        var url = url
        if query.isValid {
            url += "/\(query)"
        }
        if pageIndex > -1 {
            url += "/\(pageIndex)"
        }

        let urlComponent = URLComponents(string: url)

        guard let url = urlComponent?.url else {
            assertionFailure("URL Failure")
            return nil
        }
        print(url)

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = TimeInterval(10)

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
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
}

class  ITBookDetailData: PKHParser {
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

    static func requestSearchData(pageIndex: Int, completion: @escaping (Self) -> Void) {
        Request.request(url: Self.API_BOOK_DETAIL_URL) { requestData, error in
            guard let requestData = requestData else { return }
            Self.initAsync(map: requestData, completionHandler: { (obj: Self) in
                completion(obj)
            })
        }
    }
}
