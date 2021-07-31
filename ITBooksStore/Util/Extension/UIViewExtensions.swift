    //
//  UIViewExtensions.swift
//  EZSwiftExtensions
//
//  Created by Goktug Yilmaz on 15/07/15.
//  Copyright (c) 2015 Goktug Yilmaz. All rights reserved.
//참고 https://github.com/goktugyil/EZSwiftExtensions

#if os(iOS) || os(tvOS)

import UIKit

public typealias VoidClosure = () -> Void

fileprivate var ViewNibs = [String : UIView]()
fileprivate var ViewNibSizes = [String : CGSize]()

public enum VIEW_ADD_TYPE  {
    case horizontal
    case vertical
}

public struct GoneType: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let leading = GoneType(rawValue: 1 << 0)
    public static let trailing = GoneType(rawValue: 1 << 1)
    public static let top = GoneType(rawValue: 1 << 2)
    public static let bottom = GoneType(rawValue: 1 << 3)
    public static let width = GoneType(rawValue: 1 << 4)
    public static let height = GoneType(rawValue: 1 << 5)
    
    public static let size: GoneType = [.width, .height]
    
    public static let widthLeading: GoneType = [.width, .leading]
    public static let widthTrailing: GoneType = [.width, .trailing]
    public static let widthPadding: GoneType = [.width, .leading, .trailing]
    
    public static let heightTop: GoneType = [.height, .top]
    public static let heightBottom: GoneType = [.height, .bottom]
    public static let heightPadding: GoneType = [.height, .top, .bottom]
    
    public static let padding: GoneType = [.leading, .trailing, .top, .bottom]
    public static let all: GoneType = [.leading, .trailing, .top, .bottom, .width, .height]
}

extension NSLayoutConstraint.Attribute {
    var string: String {
        switch self {
        case .left:
            return "left"
        case .right:
            return "right"
        case .top:
            return "top"
        case .bottom:
            return "bottom"
        case .leading:
            return "leading"
        case .trailing:
            return "trailing"
        case .width:
            return "width"
        case .height:
            return "height"
        case .centerX:
            return "centerX"
        case .centerY:
            return "centerY"
        case .lastBaseline:
            return "lastBaseline"
        case .firstBaseline:
            return "firstBaseline"
        case .leftMargin:
            return "leftMargin"
        case .rightMargin:
            return "rightMargin"
        case .topMargin:
            return "topMargin"
        case .bottomMargin:
            return "bottomMargin"
        case .leadingMargin:
            return "leadingMargin"
        case .trailingMargin:
            return "trailingMargin"
        case .centerXWithinMargins:
            return "centerXWithinMargins"
        case .centerYWithinMargins:
            return "centerYWithinMargins"
        case .notAnAttribute:
            return "notAnAttribute"
        @unknown default:
            return ""
        }
    }
    
}

// MARK: - AutoLayout
extension UIView {
    private struct AssociatedKeys {
        static var viewDidDisappear: UInt8 = 0
        static var viewDidDisappearCADisplayLink: UInt8 = 0
        
        static var viewDidAppear: UInt8 = 0
        static var viewDidAppearCADisplayLink: UInt8 = 0
        
        static var goneInfo: UInt8 = 0
        static var constraintInfo: UInt8 = 0
    }
    
    private class ConstraintInfo {
        var isWidthConstraint: Bool?
        var isHeightConstraint: Bool?
        var isTopConstraint: Bool?
        var isLeadingConstraint: Bool?
        var isBottomConstraint: Bool?
        var isTrailingConstraint: Bool?
        var isCenterXConstraint: Bool?
        var isCenterYConstraint: Bool?
        
        var widthConstraint: NSLayoutConstraint?
        var heightConstraint: NSLayoutConstraint?
        var topConstraint: NSLayoutConstraint?
        var leadingConstraint: NSLayoutConstraint?
        var bottomConstraint: NSLayoutConstraint?
        var trailingConstraint: NSLayoutConstraint?
        var centerXConstraint: NSLayoutConstraint?
        var centerYConstraint: NSLayoutConstraint?
        
        var widthDefaultConstraint: CGFloat?
        var heightDefaultConstraint: CGFloat?
        var topDefaultConstraint: CGFloat?
        var leadingDefaultConstraint: CGFloat?
        var bottomDefaultConstraint: CGFloat?
        var trailingDefaultConstraint: CGFloat?
        var centerXDefaultConstraint: CGFloat?
        var centerYDefaultConstraint: CGFloat?
        
        func getLayoutConstraint(attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
            var result: NSLayoutConstraint?
            switch attribute {
            case .top:
                result = topConstraint
            case .bottom:
                result = bottomConstraint
            case .leading:
                result = leadingConstraint
            case .trailing:
                result = trailingConstraint
            case .width:
                result = widthConstraint
            case .height:
                result = heightConstraint
            case .centerX:
                result = centerXConstraint
            case .centerY:
                result = centerYConstraint
            default:
                break
            }
            
            return result
        }
        
        func setLayoutConstraint(attribute: NSLayoutConstraint.Attribute, value: NSLayoutConstraint) {
            switch attribute {
            case .top:
                topConstraint = value
            case .bottom:
                bottomConstraint = value
            case .leading:
                leadingConstraint = value
            case .trailing:
                trailingConstraint = value
            case .width:
                widthConstraint = value
            case .height:
                heightConstraint = value
            case .centerX:
                centerXConstraint = value
            case .centerY:
                centerYConstraint = value
            default:
                break
            }
        }
        
        func getConstraintDefaultValue(attribute: NSLayoutConstraint.Attribute) -> CGFloat? {
            var result: CGFloat?
            switch attribute {
            case .top:
                result = topDefaultConstraint
            case .bottom:
                result = bottomDefaultConstraint
            case .leading:
                result = leadingDefaultConstraint
            case .trailing:
                result = trailingDefaultConstraint
            case .width:
                result = widthDefaultConstraint
            case .height:
                result = heightDefaultConstraint
            case .centerX:
                result = centerXDefaultConstraint
            case .centerY:
                result = centerYDefaultConstraint
            default:
                break
            }
            
            return result
        }
        
        func setConstraintDefaultValue(attribute: NSLayoutConstraint.Attribute, value: CGFloat) {
            switch attribute {
            case .top:
                topDefaultConstraint = value
            case .bottom:
                bottomDefaultConstraint = value
            case .leading:
                leadingDefaultConstraint = value
            case .trailing:
                trailingDefaultConstraint = value
            case .width:
                widthDefaultConstraint = value
            case .height:
                heightDefaultConstraint = value
            case .centerX:
                centerXDefaultConstraint = value
            case .centerY:
                centerYDefaultConstraint = value
            default:
                break
            }
        }
    }
    
    private class GoneInfo {
        var widthEmptyConstraint: NSLayoutConstraint?
        var heightEmptyConstraint: NSLayoutConstraint?
    }
    
    private var constraintInfo: ConstraintInfo {
        get {
            if let info = objc_getAssociatedObject(self, &AssociatedKeys.constraintInfo) as? ConstraintInfo {
                return info
            }
            let info = ConstraintInfo()
            objc_setAssociatedObject(self, &AssociatedKeys.constraintInfo, info, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return info
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.constraintInfo, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    private var goneInfo: GoneInfo {
        get {
            if let info = objc_getAssociatedObject(self, &AssociatedKeys.goneInfo) as? GoneInfo {
                return info
            }
            let info = GoneInfo()
            objc_setAssociatedObject(self, &AssociatedKeys.goneInfo, info, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return info
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.goneInfo, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var isWidthConstraint: Bool {
        get {
            if let value = constraintInfo.isWidthConstraint {
                return value
            }
            else {
                let value  = self.getAttributeConstrains(constraints:Set(self.constraints) , layoutAttribute: .width).count > 0
                constraintInfo.isWidthConstraint = value
                return value
            }
        }
    }
    
    public var isHeightConstraint: Bool {
        get {
            if let value = constraintInfo.isHeightConstraint {
                return value
            }
            else {
                let value  = self.getAttributeConstrains(constraints:Set(self.constraints) , layoutAttribute: .height).count > 0
                constraintInfo.isHeightConstraint = value
                return value
            }
        }
    }
    
    public var isTopConstraint: Bool {
        get {
            if let value = constraintInfo.isTopConstraint {
                return value
            }
            else {
                if let _ = self.getLayoutConstraint(.top, errorCheck: false) {
                    constraintInfo.isTopConstraint = true
                    return true
                }
                constraintInfo.isTopConstraint = false
                return false
                
            }
        }
    }
    
    public var isLeadingConstraint: Bool {
        get {
            if let value = constraintInfo.isLeadingConstraint {
                return value
            }
            else {
                if let _ = self.getLayoutConstraint(.leading, errorCheck: false) {
                    constraintInfo.isLeadingConstraint = true
                    return true
                }
                constraintInfo.isLeadingConstraint = false
                return false
            }
        }
    }
    
    public var isBottomConstraint: Bool {
        get {
            if let value = constraintInfo.isBottomConstraint {
                return value
            }
            else {
                if let _ = self.getLayoutConstraint(.bottom, errorCheck: false) {
                    constraintInfo.isBottomConstraint = true
                    return true
                }
                constraintInfo.isBottomConstraint = false
                return false
            }
        }
    }
    
    public var isTrailingConstraint: Bool {
        get {
            if let value = constraintInfo.isTrailingConstraint {
                return value
            }
            else {
                if let _ = self.getLayoutConstraint(.trailing, errorCheck: false) {
                    constraintInfo.isTrailingConstraint = true
                    return true
                }
                constraintInfo.isTrailingConstraint = false
                return false
            }
        }
    }
    
    public var isCenterXConstraint: Bool {
        get {
            if let value = constraintInfo.isCenterXConstraint {
                return value
            }
            else {
                if let _ = self.getLayoutConstraint(.centerX, errorCheck: false) {
                    constraintInfo.isCenterXConstraint = true
                    return true
                }
                constraintInfo.isCenterXConstraint = false
                return false
            }
        }
    }
    
    public var isCenterYConstraint: Bool {
        get {
            if let value = constraintInfo.isCenterYConstraint {
                return value
            }
            else {
                if let _ = self.getLayoutConstraint(.centerY, errorCheck: false) {
                    constraintInfo.isCenterYConstraint = true
                    return true
                }
                constraintInfo.isCenterYConstraint = false
                return false
            }
        }
    }
    
    
    
    
    public var widthConstraint: CGFloat {
        get {
            return self.getConstraint(.width)
        }
        set {
            self.setConstraint(.width, newValue)
        }
    }
    
    public var heightConstraint: CGFloat {
        get {
            return self.getConstraint(.height)
        }
        set {
            self.setConstraint(.height, newValue)
        }
    }
    
    public var topConstraint: CGFloat {
        get {
            return self.getConstraint(.top)
        }
        set {
            let constraint = self.getLayoutConstraint(.top)
            if constraint?.secondItem === self {
                self.setConstraint(.top, newValue * -1)
            }
            else {
                self.setConstraint(.top, newValue)
            }
        }
    }
    
    public var leadingConstraint: CGFloat {
        get {
            return self.getConstraint(.leading)
        }
        set {
            let constraint = self.getLayoutConstraint(.leading)
            if constraint?.secondItem === self {
                self.setConstraint(.leading, newValue * -1)
            }
            else {
                self.setConstraint(.leading, newValue)
            }
        }
    }
    
    public var bottomConstraint: CGFloat {
        get {
            return self.getConstraint(.bottom)
        }
        set {
            let constraint = self.getLayoutConstraint(.bottom)
            if constraint?.firstItem === self {
                self.setConstraint(.bottom, newValue * -1)
            }
            else {
                self.setConstraint(.bottom, newValue)
            }
        }
    }
    
    public var trailingConstraint: CGFloat {
        get {
            return self.getConstraint(.trailing)
        }
        set {
            let constraint = self.getLayoutConstraint(.trailing)
            if constraint?.firstItem === self {
                self.setConstraint(.trailing, newValue * -1)
            }
            else {
                self.setConstraint(.trailing, newValue)
            }
        }
    }
    
    public var centerXConstraint: CGFloat {
        get {
            return self.getConstraint(.centerX)
        }
        set {
            let constraint = self.getLayoutConstraint(.centerX)
            if constraint?.secondItem === self {
                self.setConstraint(.centerX, newValue * -1)
            }
            else {
                self.setConstraint(.centerX, newValue)
            }
        }
    }
    
    public var centerYConstraint: CGFloat {
        get {
            return self.getConstraint(.centerY)
        }
        set {
            let constraint = self.getLayoutConstraint(.centerY)
            if constraint?.secondItem === self {
                self.setConstraint(.centerY, newValue * -1)
            }
            else {
                self.setConstraint(.centerY, newValue)
            }
        }
    }
    
    public var widthDefaultConstraint: CGFloat {
        get {
            return self.getDefaultConstraint(.width)
        }
    }
    
    public var heightDefaultConstraint: CGFloat {
        get {
            return self.getDefaultConstraint(.height)
        }
    }
    
    public var topDefaultConstraint: CGFloat {
        get {
            return self.getDefaultConstraint(.top)
        }
    }
    
    public var leadingDefaultConstraint: CGFloat {
        get {
            return self.getDefaultConstraint(.leading)
        }
    }
    
    public var bottomDefaultConstraint: CGFloat {
        get {
            return self.getDefaultConstraint(.bottom)
        }
    }
    
    public var trailingDefaultConstraint: CGFloat {
        get {
            return self.getDefaultConstraint(.trailing)
        }
    }
    
    public var centerXDefaultConstraint: CGFloat {
        get {
            return self.getDefaultConstraint(.centerX)
        }
    }
    
    public var centerYDefaultConstraint: CGFloat {
        get {
            return self.getDefaultConstraint(.centerY)
        }
    }
    
    public func getConstraint(_ layoutAttribute: NSLayoutConstraint.Attribute) -> CGFloat {
        return self.getLayoutConstraint(layoutAttribute)?.constant ?? 0
    }
    
    public func getDefaultConstraint(_ layoutAttribute: NSLayoutConstraint.Attribute) -> CGFloat {
        
        self.getLayoutConstraint(layoutAttribute)
        if let value = constraintInfo.getConstraintDefaultValue(attribute: layoutAttribute) {
            return value
        }
        
        assertionFailure("Error getDefaultConstraint")
        return 0.0
    }
    
    public func setConstraint(_ layoutAttribute: NSLayoutConstraint.Attribute, _ value: CGFloat) {
        self.getLayoutConstraint(layoutAttribute)?.constant = value
        setNeedsLayout()
    }
    
    public func getConstraint(_ layoutAttribute: NSLayoutConstraint.Attribute, toTaget: UIView) -> NSLayoutConstraint? {
        let constraints = self.getContraints(self.topParentViewView, checkSub: true)
        var constraintsTemp = self.getAttributeConstrains(constraints: constraints, layoutAttribute: layoutAttribute)
        constraintsTemp = constraintsTemp.lazy.filter { (value) -> Bool in
            return value.firstItem === toTaget || value.secondItem === toTaget
        }
        //        assert(constraintsTemp.first != nil, "not find TagetView")
        return constraintsTemp.first
    }
    
    
    public var topParentViewView: UIView {
        guard let superview = superview else {
            return  self
        }
        return superview.topParentViewView
        
    }
    public var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    @inline(__always) public func getContraints(_ view: UIView, checkSub: Bool = false) -> Set<NSLayoutConstraint> {
        var result = Set<NSLayoutConstraint>()
        result.reserveCapacity(100)
        if checkSub {
            for subView in view.subviews {
                result = result.union(self.getContraints(subView, checkSub: checkSub))
            }
        }
        
        result = result.union(view.constraints)
        
        
        return result
    }
    
    
    
    @inline(__always) public func getAttributeConstrains(constraints: Set<NSLayoutConstraint>, layoutAttribute: NSLayoutConstraint.Attribute) -> Array<NSLayoutConstraint> {
        var constraintsTemp = Array<NSLayoutConstraint>()
        constraintsTemp.reserveCapacity(100)
        for constraint in constraints {
            
            switch layoutAttribute {
            case .width, .height:
                if type(of:constraint) === NSLayoutConstraint.self {
                    if  constraint.firstItem === self && constraint.firstAttribute == layoutAttribute && constraint.secondItem == nil {
                        if self is UIButton || self is UILabel || self is UIImageView {
                            constraintsTemp.append(constraint)
                        }
                        else {
                            if self is UIButton || self is UILabel || self is UIImageView {
                                constraintsTemp.append(constraint)
                            }
                            else {
                                constraintsTemp.append(constraint)
                            }
                        }
                    }
                    else if  constraint.firstAttribute == layoutAttribute && constraint.secondAttribute == layoutAttribute {
                        if constraint.firstItem === self || constraint.secondItem === self {
                            constraintsTemp.append(constraint)
                        }
                    }
                }
            case .centerX, .centerY:
                if constraint.firstAttribute == layoutAttribute  && constraint.secondAttribute == layoutAttribute {
                    if (constraint.firstItem === self && (constraint.secondItem === self.superview || constraint.secondItem is UILayoutGuide)) ||
                        (constraint.secondItem === self && (constraint.firstItem === self.superview || constraint.firstItem is UILayoutGuide)) {
                        constraintsTemp.append(constraint)
                    }
                    else if constraint.firstItem === self || constraint.secondItem === self {
                        constraintsTemp.append(constraint)
                    }
                }
            case .top :
                if  constraint.firstItem === self && constraint.firstAttribute == .top  && constraint.secondAttribute == .bottom {
                    constraintsTemp.append(constraint)
                }
                else if  constraint.secondItem === self && constraint.secondAttribute == .top  && constraint.firstAttribute == .bottom {
                    constraintsTemp.append(constraint)
                }
                else if constraint.firstAttribute == .top  && constraint.secondAttribute == .top {
                    if (constraint.firstItem === self && constraint.secondItem === self.superview ) ||
                        (constraint.secondItem === self && constraint.firstItem === self.superview ) {
                        constraintsTemp.append(constraint)
                    }
                    else {
                        if (constraint.firstItem === self && constraint.secondItem is UILayoutGuide) ||
                            (constraint.secondItem === self &&  constraint.firstItem is UILayoutGuide) {
                            constraintsTemp.append(constraint)
                        }
                        else if constraint.firstItem === self || constraint.secondItem === self {
                            constraintsTemp.append(constraint)
                        }
                    }
                }
            case .bottom :
                if  constraint.firstItem === self && constraint.firstAttribute == .bottom  && constraint.secondAttribute == .top {
                    constraintsTemp.append(constraint)
                }
                else if  constraint.secondItem === self && constraint.secondAttribute == .bottom  && constraint.firstAttribute == .top {
                    constraintsTemp.append(constraint)
                }
                else if constraint.firstAttribute == .bottom  && constraint.secondAttribute == .bottom {
                    if (constraint.firstItem === self && constraint.secondItem === self.superview ) ||
                        (constraint.secondItem === self && constraint.firstItem === self.superview ) {
                        constraintsTemp.append(constraint)
                    }
                    else  {
                        if (constraint.firstItem === self && constraint.secondItem is UILayoutGuide) ||
                            (constraint.secondItem === self &&  constraint.firstItem is UILayoutGuide) {
                            constraintsTemp.append(constraint)
                        }
                        else if constraint.firstItem === self || constraint.secondItem === self {
                            constraintsTemp.append(constraint)
                        }
                    }
                }
            case .leading :
                if  constraint.firstItem === self && constraint.firstAttribute == .leading  && constraint.secondAttribute == .trailing {
                    constraintsTemp.append(constraint)
                }
                else if  constraint.secondItem === self && constraint.secondAttribute == .leading  && constraint.firstAttribute == .trailing {
                    constraintsTemp.append(constraint)
                }
                else if constraint.firstAttribute == .leading  && constraint.secondAttribute == .leading {
                    if (constraint.firstItem === self && constraint.secondItem === self.superview ) ||
                        (constraint.secondItem === self && constraint.firstItem === self.superview ) {
                        constraintsTemp.append(constraint)
                    }
                    else  {
                        if (constraint.firstItem === self && constraint.secondItem is UILayoutGuide) ||
                            (constraint.secondItem === self &&  constraint.firstItem is UILayoutGuide) {
                            constraintsTemp.append(constraint)
                        }
                        else if constraint.firstItem === self || constraint.secondItem === self {
                            constraintsTemp.append(constraint)
                        }
                    }
                }
            case .trailing :
                if  constraint.firstItem === self && constraint.firstAttribute == .trailing  && constraint.secondAttribute == .leading {
                    constraintsTemp.append(constraint)
                }
                else if  constraint.secondItem === self && constraint.secondAttribute == .trailing  && constraint.firstAttribute == .leading {
                    constraintsTemp.append(constraint)
                }
                else if constraint.firstAttribute == .trailing  && constraint.secondAttribute == .trailing {
                    if (constraint.firstItem === self && constraint.secondItem === self.superview ) ||
                        (constraint.secondItem === self && constraint.firstItem === self.superview ) {
                        constraintsTemp.append(constraint)
                    }
                    else {
                        if (constraint.firstItem === self && constraint.secondItem is UILayoutGuide) ||
                            (constraint.secondItem === self &&  constraint.firstItem is UILayoutGuide) {
                            constraintsTemp.append(constraint)
                        }
                        else if constraint.firstItem === self || constraint.secondItem === self {
                            constraintsTemp.append(constraint)
                        }
                    }
                }
                
                
                
            default :
                assertionFailure("not supput \(layoutAttribute)")
            }
        }
        
        
        return constraintsTemp
    }
    
    public func getLayoutAllConstraints(_ layoutAttribute: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {
        var resultConstraints = Array<NSLayoutConstraint>()
        resultConstraints.reserveCapacity(100)
        var constraints = Set<NSLayoutConstraint>()
        constraints.reserveCapacity(100)
        
        if layoutAttribute == .width || layoutAttribute == .height {
            
            constraints = self.getContraints(self)
            resultConstraints += self.getAttributeConstrains(constraints: constraints, layoutAttribute: layoutAttribute)
            
            if resultConstraints.count == 0 {
                if let view = superview {
                    constraints = self.getContraints(view)
                    resultConstraints += self.getAttributeConstrains(constraints: constraints, layoutAttribute: layoutAttribute)
                }
            }
            
            if resultConstraints.count == 0 {
                constraints = self.getContraints(self.topParentViewView, checkSub: true)
                resultConstraints += self.getAttributeConstrains(constraints: constraints, layoutAttribute: layoutAttribute)
            }
        }
        else {
            
            if let view = superview {
                constraints = self.getContraints(view)
                resultConstraints += self.getAttributeConstrains(constraints: constraints, layoutAttribute: layoutAttribute)
            }
            
            if resultConstraints.count == 0 {
                constraints = self.getContraints(self)
                resultConstraints += self.getAttributeConstrains(constraints: constraints, layoutAttribute: layoutAttribute)
            }
            
            if resultConstraints.count == 0 {
                constraints = self.getContraints(self.topParentViewView, checkSub: true)
                resultConstraints += self.getAttributeConstrains(constraints: constraints, layoutAttribute: layoutAttribute)
            }
        }
        
        return resultConstraints
    }
    
    @discardableResult
    public func getLayoutConstraint(_ layoutAttribute: NSLayoutConstraint.Attribute, errorCheck: Bool = true) -> NSLayoutConstraint? {
        
        if let value = constraintInfo.getLayoutConstraint(attribute: layoutAttribute) {
            return value
        }
        
        let constraintsTemp = getLayoutAllConstraints(layoutAttribute)
        
        if constraintsTemp.count == 0 {
            if errorCheck {
                assertionFailure("\n\n🔗 ------------------------------------------------ \n\(self.constraints)\nAutoLayout Not Make layoutAttribute : \(layoutAttribute.string) \nView: \(self)\n🔗 ------------------------------------------------ \n\n")
            }
            return nil
        }
        
        let constraintsSort: Array = constraintsTemp.sorted(by: { (obj1, obj2) -> Bool in
            return obj1.priority.rawValue > obj2.priority.rawValue
        })
        
        
        let result : NSLayoutConstraint? = constraintsSort.first
        if let result = result  {
            constraintInfo.setLayoutConstraint(attribute: layoutAttribute, value: result)
            
            if constraintInfo.getConstraintDefaultValue(attribute: layoutAttribute) == nil {
                constraintInfo.setConstraintDefaultValue(attribute: layoutAttribute, value: result.constant)
            }
        }
        
        return result
    }
    
    public func copyView() -> AnyObject
    {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self))! as AnyObject
    }
    
    public func addSubViewAutoLayout(_ subview: UIView) {
        self.addSubViewAutoLayout(subview, edgeInsets: UIEdgeInsets.zero)
    }
    
    public func addSubViewAutoLayout(_ subview: UIView, edgeInsets: UIEdgeInsets) {
        self.addSubview(subview)
        self.setSubViewAutoLayout(subview, edgeInsets: edgeInsets)
    }
    
    public func addSubViewAutoLayout(insertView: UIView, subview: UIView, edgeInsets: UIEdgeInsets, isFront: Bool) {
        if (isFront) {
            self.insertSubview(insertView, belowSubview:subview);
        }
        else {
            self.insertSubview(insertView, aboveSubview:subview);
        }
        self.setSubViewAutoLayout(insertView, edgeInsets: edgeInsets)
    }
    
    public func setSubViewAutoLayout(_ subview: UIView, edgeInsets: UIEdgeInsets) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        
        let views: Dictionary = ["subview": subview]
        let edgeInsetsDic: Dictionary = ["top" : (edgeInsets.top), "left" : (edgeInsets.left), "bottom" : (edgeInsets.bottom), "right" : (edgeInsets.right)]
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat:"H:|-(left)-[subview]-(right)-|",
                                                           options:NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics:edgeInsetsDic,
                                                           views:views))
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat:"V:|-(top)-[subview]-(bottom)-|",
                                                           options:NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                           metrics:edgeInsetsDic,
                                                           views:views))
    }
    
    public func addSubViewAutoLayout(subviews: Array<UIView>, addType: VIEW_ADD_TYPE, edgeInsets: UIEdgeInsets) {
        var constraints = String()
        var views = Dictionary<String,UIView>()
        var metrics: Dictionary = ["top" : (edgeInsets.top), "left" : (edgeInsets.left), "bottom" : (edgeInsets.bottom), "right" : (edgeInsets.right)];
        
        for (idx, obj) in subviews.enumerated() {
            obj.translatesAutoresizingMaskIntoConstraints = false;
            self.addSubview(obj)
            views["view\(idx)"] = obj
            
            
            if addType == .horizontal {
                self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat:"V:|-(top)-[view\(idx)]-(bottom)-|",
                    options:NSLayoutConstraint.FormatOptions(rawValue: 0),
                    metrics:["top" : (edgeInsets.top), "bottom" : (edgeInsets.bottom)],
                    views:views))
                
                metrics["width\(idx)"] = (obj.frame.size.width)
                
                if subviews.count == 1 {
                    constraints += "H:|-(left)-[view\(idx)(width\(idx))]-(right)-|"
                    
                    self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat:constraints,
                                                                       options:NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                       metrics:metrics,
                                                                       views:views))
                    
                }
                else {
                    if idx == 0 {
                        constraints += "H:|-(left)-[view\(idx)(width\(idx))]"
                    }
                    else if idx == subviews.count - 1 {
                        constraints += "[view\(idx)(width\(idx))]-(right)-|"
                        
                        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat:constraints,
                                                                           options:NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                           metrics:metrics,
                                                                           views:views))
                    }
                    else {
                        constraints += "[view\(idx)(width\(idx))]"
                    }
                }
                
                
            }
            else {
                self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat:"H:|-(left)-[view\(idx)]-(right)-|",
                    options:NSLayoutConstraint.FormatOptions(rawValue: 0),
                    metrics:["left" : (edgeInsets.left), "right" : (edgeInsets.right)],
                    views:views))
                
                metrics["height\(idx)"] = (obj.frame.size.height)
                
                if subviews.count == 1 {
                    constraints += "V:|-(top)-[view\(idx)(height\(idx))]-(bottom)-|"
                    
                    self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat:constraints,
                                                                       options:NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                       metrics:metrics,
                                                                       views:views))
                }
                else {
                    if idx == 0 {
                        constraints += "V:|-(top)-[view\(idx)(height\(idx))]"
                        
                    }
                    else if idx == subviews.count - 1 {
                        constraints += "[view\(idx)(height\(idx))]-(bottom)-|"
                        
                        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat:constraints,
                                                                           options:NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                           metrics:metrics,
                                                                           views:views))
                    }
                    else {
                        constraints += "[view\(idx)(height\(idx))]"
                    }
                }
                
            }
            
        }
        
    }
    
    public func removeSuperViewAllConstraints() {
        guard let superview: UIView = self.superview else { return}
        
        for c: NSLayoutConstraint in superview.constraints {
            if c.firstItem === self || c.secondItem === self {
                superview.removeConstraint(c)
            }
        }
    }
    
    public func removeAllConstraints() {
        self.removeSuperViewAllConstraints()
        self.removeConstraints(self.constraints)
        self.translatesAutoresizingMaskIntoConstraints = true
    }
    
    
    private var viewDidAppearCADisplayLink: CADisplayLink? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.viewDidAppearCADisplayLink) as? CADisplayLink
        }
        set {
            objc_setAssociatedObject ( self, &AssociatedKeys.viewDidAppearCADisplayLink, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc private func onViewDidAppear() {
        let windowRect = self.superview?.convert(self.frame, to: nil) ?? .zero
        if windowRect == .zero {
            self.viewDidAppearCADisplayLink?.invalidate()
            self.viewDidAppearCADisplayLink = nil
            return
        }
        
        if self.isVisible {
            self.viewDidAppearCADisplayLink?.invalidate()
            self.viewDidAppearCADisplayLink = nil
            self.viewDidAppear?()
        }
    }
    
    public var viewDidAppear: VoidClosure? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.viewDidAppear) as? VoidClosure
        }
        set {
            objc_setAssociatedObject ( self, &AssociatedKeys.viewDidAppear, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            viewDidAppearCADisplayLink?.invalidate()
            if newValue != nil {
                viewDidAppearCADisplayLink = CADisplayLink(target: self, selector: #selector(onViewDidAppear))
                viewDidAppearCADisplayLink?.add(to: .current, forMode: .common)
                if #available(iOS 10.0, *) {
                    viewDidAppearCADisplayLink?.preferredFramesPerSecond = 5
                } else {
                    viewDidAppearCADisplayLink?.frameInterval = 5
                }
            }
            else {
                viewDidAppearCADisplayLink = nil
            }
        }
    }
    
    private var viewDidDisappearCADisplayLink: CADisplayLink? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.viewDidDisappearCADisplayLink) as? CADisplayLink
        }
        set {
            objc_setAssociatedObject ( self, &AssociatedKeys.viewDidDisappearCADisplayLink, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc private func onViewDidDisappear() {
        let windowRect = self.superview?.convert(self.frame, to: nil) ?? .zero
        if windowRect == .zero {
            self.viewDidDisappearCADisplayLink?.invalidate()
            self.viewDidDisappearCADisplayLink = nil
            return
        }
        
        if self.isVisible == false {
            self.viewDidDisappearCADisplayLink?.invalidate()
            self.viewDidDisappearCADisplayLink = nil
            self.viewDidDisappear?()
        }
    }
    
    public var viewDidDisappear: VoidClosure? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.viewDidDisappear) as? VoidClosure
        }
        set {
            objc_setAssociatedObject ( self, &AssociatedKeys.viewDidDisappear, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            
            viewDidDisappearCADisplayLink?.invalidate()
            if newValue != nil {
                viewDidDisappearCADisplayLink = CADisplayLink(target: self, selector: #selector(onViewDidDisappear))
                viewDidDisappearCADisplayLink?.add(to: .current, forMode: .common)
                if #available(iOS 10.0, *) {
                    viewDidDisappearCADisplayLink?.preferredFramesPerSecond = 5
                } else {
                    viewDidDisappearCADisplayLink?.frameInterval = 5
                }
            }
            else {
                viewDidDisappearCADisplayLink = nil
            }
        }
    }
    
    public var isVisible: Bool {
        
        if self.window == nil {
            return false
        }
        
        var currentView: UIView = self
        while let superview = currentView.superview {
            
            if (superview.bounds).intersects(currentView.frame) == false {
                return false;
            }
            
            if currentView.isHidden {
                return false
            }
            
            currentView = superview
        }
        
        return true
    }
    
    public var gone: Bool {
        get {
            fatalError("You cannot read from this object.")
        }
        set {
            newValue ? gone() : goneRemove()
        }
    }
    
    public var goneWidth: Bool {
        get {
            fatalError("You cannot read from this object.")
        }
        set {
            newValue ? gone(.widthPadding) : goneRemove(.widthPadding)
        }
    }
    
    public var goneHeight: Bool {
        get {
            fatalError("You cannot read from this object.")
        }
        set {
            newValue ? gone(.heightPadding) : goneRemove(.heightPadding)
        }
    }
    
    public func gone(_ type: GoneType = .all) {
        guard type.isEmpty == false else { return }
        isHidden = true
        
        if type.contains(.width) {
            if isWidthConstraint {
                widthConstraint = 0
            }
            else {
                if let c = self.goneInfo.widthEmptyConstraint {
                    c.constant = 0
                }
                else {
                    let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 0)
                    addConstraint(constraint)
                    goneInfo.widthEmptyConstraint = constraint
                }
                
            }
        }
        if type.contains(.height) {
            if isHeightConstraint {
                heightConstraint = 0
            }
            else {
                if let c = self.goneInfo.heightEmptyConstraint {
                    c.constant = 0
                }
                else {
                    let constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 0)
                    addConstraint(constraint)
                    goneInfo.heightEmptyConstraint = constraint
                }
                
            }
        }
        if type.contains(.leading)  {
            if isLeadingConstraint {
                leadingConstraint = 0
            }
        }
        if type.contains(.trailing)  {
            if isTrailingConstraint {
                trailingConstraint = 0
            }
        }
        if type.contains(.top) {
            if isTopConstraint {
                topConstraint = 0
            }
        }
        if type.contains(.bottom) {
            if isBottomConstraint {
                bottomConstraint = 0
            }
        }
    }
    
    public func goneRemove(_ type: GoneType = .all) {
        isHidden = false
        
        if type.contains(.width) {
            if let c = goneInfo.widthEmptyConstraint {
                removeConstraint(c)
                goneInfo.widthEmptyConstraint = nil
            }
            else if isWidthConstraint {
                widthConstraint = widthDefaultConstraint
            }
        }
        if type.contains(.height) {
            if let c = goneInfo.heightEmptyConstraint {
                removeConstraint(c)
                goneInfo.heightEmptyConstraint = nil
            }
            else if isHeightConstraint {
                heightConstraint = heightDefaultConstraint
            }
        }
        if type.contains(.leading) {
            if isLeadingConstraint {
                leadingConstraint = leadingDefaultConstraint
            }
        }
        if type.contains(.trailing) {
            if isTrailingConstraint {
                trailingConstraint = trailingDefaultConstraint
            }
        }
        if type.contains(.top) {
            if isTopConstraint {
                topConstraint = topDefaultConstraint
            }
        }
        if type.contains(.bottom) {
            if isBottomConstraint {
                bottomConstraint = bottomDefaultConstraint
            }
        }
    }
}


extension UIView {
    
    var safeTopAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.topAnchor
        } else {
            return self.topAnchor
        }
    }
    
    var safeLeftAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *){
            return self.safeAreaLayoutGuide.leftAnchor
        }else {
            return self.leftAnchor
        }
    }
    
    var safeRightAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *){
            return self.safeAreaLayoutGuide.rightAnchor
        }else {
            return self.rightAnchor
        }
    }
    
    var safeBottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return self.safeAreaLayoutGuide.bottomAnchor
        } else {
            return self.bottomAnchor
        }
    }
}

// MARK: - IBInspectable
extension UIView {
    @IBInspectable public var tagName: String? {
        get {
            return self.tag_name
        }
        set {
            self.tag_name = newValue
        }
    }

    @IBInspectable public var rotationDegrees: CGFloat {
        get {
            return atan2(self.transform.b, self.transform.a)
        }
        set {
            let radians: CGFloat = CGFloat(Double.pi) * newValue / 180.0
            self.transform = CGAffineTransform(rotationAngle: radians)
        }
    }

    @IBInspectable public var borderColor: UIColor? {
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
        set {
            guard self.layer.borderColor != newValue?.cgColor else { return }
            self.layer.borderColor = newValue?.cgColor
            setNeedsDisplay()
        }
    }

    @IBInspectable public var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            guard self.layer.borderWidth != newValue else { return }
            self.layer.borderWidth = newValue
            self.layer.masksToBounds = true
            setNeedsDisplay()
        }
    }

    @IBInspectable public var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            guard self.layer.cornerRadius != newValue else { return }
            self.layer.cornerRadius = newValue
            self.layer.masksToBounds = true
            self.clipsToBounds = true
            setNeedsDisplay()
        }
    }
}

// MAKR: - Rect
extension UIView {
    public var x: CGFloat {
        get {
            return self.frame.origin.x
        } set(value) {
            self.frame = CGRect(x: value, y: self.y, width: self.w, height: self.h)
        }
    }

    public var minX: CGFloat {
        get {
            return self.frame.minX
        }
    }

    public var midX: CGFloat {
        get {
            return self.frame.midX
        }
    }

    public var maxX: CGFloat {
        get {
            return self.frame.maxX
        }
        set {
            self.frame.x = newValue - self.w
        }
    }

    public var y: CGFloat {
        get {
            return self.frame.origin.y
        } set(value) {
            self.frame = CGRect(x: self.x, y: value, width: self.w, height: self.h)
        }
    }

    public var minY: CGFloat {
        get {
            return self.frame.minY
        }
    }

    public var midY: CGFloat {
        get {
            return self.frame.midY
        }
    }

    public var maxY: CGFloat {
        get {
            return self.frame.maxY
        }
        set {
            self.frame.y = newValue - self.h
        }
    }

    public var w: CGFloat {
        get {
            return self.frame.size.width
        } set(value) {
            self.frame = CGRect(x: self.x, y: self.y, width: value, height: self.h)
        }
    }

    public var h: CGFloat {
        get {
            return self.frame.size.height
        } set(value) {
            self.frame = CGRect(x: self.x, y: self.y, width: self.w, height: value)
        }
    }

    public var left: CGFloat {
        get {
            return self.x
        } set(value) {
            self.x = value
        }
    }

    public var right: CGFloat {
        get {
            return self.x + self.w
        } set(value) {
            self.x = value - self.w
        }
    }

    public var centerX: CGFloat {
        get {
            return self.center.x
        } set(value) {
            self.center.x = value
        }
    }

    public var centerY: CGFloat {
        get {
            return self.center.y
        } set(value) {
            self.center.y = value
        }
    }

    public var size: CGSize {
        get {
            return self.frame.size
        } set(value) {
            self.frame = CGRect(origin: self.frame.origin, size: value)
        }
    }
}
#endif


