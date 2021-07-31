//
//  CGRectExtension.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import Foundation
import UIKit

/// 0.5 단위 버림 처림
/// 0.5 작으면 0
/// 0.5 보다 크면 0.5
/// - Returns: 0.5 단위 버림 처리
@inline(__always) public func floorUI(_ value: CGFloat) -> CGFloat {
    let roundValue = round(value)
    let floorValue = floor(value)
    if roundValue == floorValue {
        return CGFloat(roundValue)
    }
    return CGFloat(roundValue - 0.5)
}

/// 0.5 단위 올림 처리
/// 0.5 작으면 0.5
/// 0.5 보다 크면 1
/// - Returns: 0.5 단위 올림 처리
@inline(__always) public func ceilUI(_ value: CGFloat) -> CGFloat {
    let roundValue = round(value)
    let ceilValue = ceil(value)
    if roundValue == ceilValue {
        return CGFloat(roundValue)
    }
    return CGFloat(roundValue + 0.5)
}

extension CGRect {
    public init(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) {
        self.init(x: x, y: y, width: w, height: h)
    }

    public var x: CGFloat {
        get {
            return self.origin.x
        }
        set(value) {
            self.origin.x = value
        }
    }

    public var y: CGFloat {
        get {
            return self.origin.y
        }
        set(value) {
            self.origin.y = value
        }
    }

    public var w: CGFloat {
        get {
            return self.size.width
        }
        set(value) {
            self.size.width = value
        }
    }

    public var h: CGFloat {
        get {
            return self.size.height
        }
        set(value) {
            self.size.height = value
        }
    }

    public var center: CGPoint {
        get {
            return CGPoint(x: x + (w / 2.0), y: y + (h / 2.0))
        }
        set {
            x = newValue.x - (w / 2.0)
            y = newValue.y - (h / 2.0)
        }
    }
}

extension CGSize {
    public func ratioSize(setWidth: CGFloat) -> CGSize {
        return CGSize(width: setWidth, height: ratioHeight(setWidth: setWidth) )
    }

    public func ratioHeight(setWidth: CGFloat) -> CGFloat {
        guard self.width != 0 else { return 0 }
        if self.width == setWidth {
            return self.height
        }
        let origin: CGFloat = self.height * setWidth / self.width
        return ceilUI(origin)
    }

    public func ratioWidth(setHeight: CGFloat) -> CGFloat {
        guard self.height != 0 else { return 0 }
        if self.height == setHeight {
            return self.width
        }
        let origin: CGFloat = self.width * setHeight / self.height
        return ceilUI(origin)
    }

    public var w: CGFloat {
        get {
            return self.width
        }
        set(value) {
            self.width = value
        }
    }

    public var h: CGFloat {
        get {
            return self.height
        }
        set(value) {
            self.height = value
        }
    }
}
