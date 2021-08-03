//
//  DictionaryExtensions.swift
//  ITBooksStore
//
//  Created by pkh on 2021/08/03.
//

import Foundation

extension Dictionary {
    public func jsonString() -> String? {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions()) {
            if let jsonStr: String = String(data: jsonData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
                return jsonStr
            }
            return ""
        }
        return nil
    }

}
