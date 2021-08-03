//
//  CommonFunction.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import UIKit


typealias AlertActionHandler = ((UIAlertAction) -> Void)

/// only 'title' is required parameter. you can ignore rest of them
///
/// - Parameters:
///   - title: Title string. required.
///   - message: Message for alert.
///   - okTitle: Title for confirmation action. If you don't probide 'okHandler', this will be ignored.
///   - okHandler: Closure for confirmation action. If it's implemented, alertController will have two alertAction.
///   - cancelTitle: Title for cancel/dissmis action.
///   - cancelHandler: Closure for cancel/dissmis action.
///   - completion: Closure will be called right after the alertController presented.
func alert(title: String,
           message: String? = nil,
           okTitle: String = "OK",
           okHandler: AlertActionHandler? = nil,
           cancelTitle: String? = nil,
           cancelHandler: AlertActionHandler? = nil,
           completion: (() -> Void)? = nil) {

    let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

    if let okClosure = okHandler {
        let okAction: UIAlertAction = UIAlertAction(title: okTitle, style: .default, handler: okClosure)
        alert.addAction(okAction)
        let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler)
        alert.addAction(cancelAction)
    }
    else {
        if let cancelTitle = cancelTitle {
            let cancelAction: UIAlertAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: cancelHandler)
            alert.addAction(cancelAction)
        }
        else {
            let cancelAction: UIAlertAction = UIAlertAction(title: "확인", style: .cancel, handler: cancelHandler)
            alert.addAction(cancelAction)
        }

    }
    //        self.present(alert, animated: true, completion: completion)
    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
}

// Font
enum FontName: String {
    case APPLE_SD_MEDIUM = "AppleSDGothicNeo-Medium"
    case APPLE_SD_REGULAR = "AppleSDGothicNeo-Regular"
    case APPLE_SD_BOLD = "AppleSDGothicNeo-Bold"
    case APPLE_SD_THIN = "AppleSDGothicNeo-Thin"
    case APPLE_SD_LIGHT = "AppleSDGothicNeo-Light"
    case APPLE_SD_SEMIBOLD = "AppleSDGothicNeo-SemiBold"
    case APPLE_SD_ULTRA_LIGHT = "AppleSDGothicNeo-UltraLight"

    func size(_ size: CGFloat) -> UIFont {
        return UIFont(name: self.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
    }

}
