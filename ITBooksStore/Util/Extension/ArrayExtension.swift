//
//  ArrayExtension.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import Foundation

extension Array {
    subscript(safe index: Int?) -> Element? {
        guard let index = index else { return nil }
        if indices.contains(index) {
            return self[index]
        }
        else {
            return nil
        }
    }
}

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        if let index = firstIndex(of: object) {
            remove(at: index)
        }
    }
}
