//
//  UIButtonExtension.swift
//  PhotoCollectoinViewTest
//
//  Created by pkh on 2021/08/02.
//

import UIKit

private var controlAction_Key: UInt8 = 0

private class ClosureSleeve {
    let closure: (_ btn: UIButton) -> Void

    public init (_ closure: @escaping (_ btn: UIButton) -> Void) {
        self.closure = closure
    }

    @objc public func invoke (btn: UIButton) {
        closure(btn)
    }
}

extension UIControl {
    public func addAction(for controlEvents: UIControl.Event, _ closure: @escaping (_ btn: UIButton) -> Void) {
        let sleeve = ClosureSleeve(closure)
        removeTarget(nil, action: nil, for: controlEvents)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)
        objc_setAssociatedObject(self, &controlAction_Key, sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
