//
//  StringExtensions.swift
//  Test
//
//  Created by pkh on 2018. 8. 14..
//  Copyright © 2018년 pkh. All rights reserved.
//

import Foundation
#if os(OSX)
import AppKit
#endif

#if os(iOS) || os(tvOS)
import UIKit
#endif

extension String {
    public var isValid: Bool {
        if self.isEmpty || self.count == 0 || self.trim().count == 0 || self == "(null)" || self == "null" || self == "nil" {
            return false
        }

        return true
    }

    public func trim() -> String {
        let str: String = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return str
    }

    public func contains(_ find: String) -> Bool {
        return self.range(of: find) != nil
    }

    public func replace(_ of: String, _ with: String) -> String {
        return self.replacingOccurrences(of: of, with: with, options: .literal, range: nil)
    }

    ///   Trims white space and new line characters, returns a new string
    public func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func toInt() -> Int {
        if let num = NumberFormatter().number(from: self) {
            return num.intValue
        }
        else {
            return 0
        }
    }

    ///   Converts String to Double
    public func toDouble() -> Double {
        if let num = NumberFormatter().number(from: self) {
            return num.doubleValue
        }
        else {
            return 0
        }
    }

    ///   Converts String to Float
    public func toFloat() -> Float {
        if let num = NumberFormatter().number(from: self) {
            return num.floatValue
        }
        else {
            return 0
        }
    }

    ///   Converts String to CGFloat
    public func toCGFloat() -> CGFloat {
        if let num = NumberFormatter().number(from: self) {
            return CGFloat(num.floatValue)
        }
        else {
            return 0
        }
    }

    ///   Converts String to Bool
    public func toBool() -> Bool {
        let trimmedString = trimmed().lowercased()
        if trimmedString == "true" || trimmedString == "Y" || trimmedString == "y" || trimmedString == "True" {
            return true
        }
        else {
            return false
        }
    }


    public func toDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }

    func convertPriceFormat() -> String {
        guard self.isValid else {
            return ""
        }
        let value = self.replace(",", "")
        guard let value = Double(value) else { return self }

        let price: NSNumber = NSNumber(floatLiteral: value)
        let formatter: NumberFormatter = NumberFormatter()
        formatter.groupingSeparator = ","
        formatter.numberStyle = .decimal
        if let result: String = formatter.string(from: price) {
            return result
        }
        return ""
    }

    func underLine() -> NSMutableAttributedString {
        let attributeString = NSMutableAttributedString(string: self)
        attributeString.addAttribute(NSAttributedString.Key.underlineStyle, value: 1, range: NSRange(location: 0, length: attributeString.length))
        return attributeString
    }

    func height(maxWidth: CGFloat, font: UIFont) -> CGFloat {
       return self.size(maxWidth: maxWidth, font: font).height
   }

    func size(maxWidth: CGFloat, font: UIFont) -> CGSize {
        let constraintSize: CGSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let boundingBox: CGRect = self.boundingRect(with: constraintSize, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        return CGSize(width: ceilUI(boundingBox.width), height: ceilUI(boundingBox.height))
    }

}

