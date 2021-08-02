//
//  RouterProtocol.swift
//  pkh0225
//
//  Created by pkh on 2021/07/15.
//

import UIKit

var cacheViewControllers = NSCache<NSString, UIViewController>()
var cacheStoryBoardInstance = NSCache<NSString, UIStoryboard>()

protocol RouterProtocol: UIViewController {
    static var storyboardName: String { get }
}

extension RouterProtocol where Self: UIViewController {
    // MARK:- assembleModule
    private static func assembleModule() -> Self {
        if self.storyboardName.isValid {
            if let storyboard: UIStoryboard = cacheStoryBoardInstance.object(forKey: self.storyboardName as NSString) {
                if let vc = storyboard.instantiateViewController(withIdentifier: self.className) as? Self {
                    return vc
                }
            }
            else {
                let storyboard = UIStoryboard(name: self.storyboardName, bundle: Bundle.main)
                if let vc = storyboard.instantiateViewController(withIdentifier: self.className) as? Self {
                    return vc
                }
            }
        }

        return self.init()
//        fatalError("======= \(self.className) is not RouterProtocol ")
    }

    // MARK:- getViewController
    static func getViewController(cache: Bool = false) -> Self {
        if cache {
            if let vc = cacheViewControllers.object(forKey: self.className as NSString) {
                return vc as! Self
            }
            else {
                return  assembleModule()
            }
        }
        return assembleModule()

    }

    // MARK:- pushViewController
    @discardableResult
    static func pushViewController(animated: Bool = true) -> Self {
        print(" ✈️ pushViewController : \(self.className)")
        let vc = getViewController()
        NavigationManager.shared.mainNavigation?.pushViewController(vc, animated: animated)
        return vc
    }

    // MARK:- transparent presentViewController
    @discardableResult
    static func transparentPresentViewController(animated: Bool = true) -> Self {
        print(" ✈️ transparentPresentViewController : \(self.className)")
        let vc = getViewController()
        NavigationManager.shared.mainNavigation?.definesPresentationContext = false
        vc.modalPresentationStyle = .overFullScreen
        NavigationManager.shared.mainNavigation?.visibleViewController?.present(vc, animated: animated, completion: nil)
        return vc
    }

}
