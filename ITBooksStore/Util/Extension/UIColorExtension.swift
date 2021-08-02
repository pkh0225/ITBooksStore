//
//  UIColorExtension.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import Foundation
import UIKit

private var CellBackGroundColorIndex: Int = -1
private let cellBackGroundColorInfo: [UIColor] = [ UIColor(hex: 0xf6f3e6),
                                                   UIColor(hex: 0xf3eae0),
                                                   UIColor(hex: 0xe5f3e0),
                                                   UIColor(hex: 0xe0edf3),
                                                   UIColor(hex: 0xe0e0f3),
                                                   UIColor(hex: 0xeae0f3),
                                                   UIColor(hex: 0xf3e0f2),
                                                   UIColor(hex: 0xf3e0e4),
                                                   UIColor(hex: 0xeae0cc),
                                                   UIColor(hex: 0xd0ede0),
                                                   UIColor(hex: 0xccd4ea),
                                                   UIColor(hex: 0xe0e0e0)]

extension UIColor {
    public convenience init(hex col: UInt32, alpha: CGFloat = 1.0) {
        let b = UInt8((col & 0xff))
        let g = UInt8(((col >> 8) & 0xff))
        let r = UInt8(((col >> 16) & 0xff))
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: alpha)
    }

    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        var alpha = alpha
        var cString: String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if (cString.count) != 6 {
            if cString.count == 8 {
                // alpha 코드 포함
                let endIdx: String.Index = cString.index(cString.startIndex, offsetBy: 1)
                let startIdx: String.Index = cString.index(cString.startIndex, offsetBy: 2)

                let alphaCode = String(cString[...endIdx])
                cString = String(cString[startIdx...])

                let alphaDeci = Int(alphaCode, radix: 16)! // hex to decimal
                let alphaVal = round(Double(alphaDeci) / 255.0 * 100) / 100 // decimal 수치로 변환 후 소숫점 두자리까지 표현
                alpha = CGFloat( alphaVal )
            }
            else {
                self.init()
            }
        }

        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)

        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0, green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0, blue: CGFloat(rgbValue & 0x0000FF) / 255.0, alpha: alpha)
    }

    class var imageBackgroundColor: UIColor {
        CellBackGroundColorIndex += 1
        if CellBackGroundColorIndex >= cellBackGroundColorInfo.count {
            CellBackGroundColorIndex = 0
        }
        return cellBackGroundColorInfo[CellBackGroundColorIndex]
    }
}
