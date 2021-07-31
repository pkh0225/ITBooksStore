//
//  UIImageViewExtension.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import Foundation
import  UIKit

extension UIImageView {
    private struct AssociatedKeys {
        static var imageDataTask: UInt8 = 0
        static var url: UInt8 = 0
    }

    private static var UrlToImageCache: NSCache<NSString, UIImage>?

    private var imageDataTask: URLSessionDataTask? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.imageDataTask) as? URLSessionDataTask
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.imageDataTask, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var url: URL? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.url) as? URL
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.url, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }


    func getChachImage(urlString: String?) -> UIImage? {
        guard let urlString = urlString, urlString.isValid else { return  nil }
        return Self.UrlToImageCache?.object(forKey: urlString as NSString)
    }

    func setUrlImage(_ urlString: String?, placeHolderImage: UIImage? = nil, backgroundColor: UIColor? = nil, transitionAnimation: Bool = true) {
        imageDataTask?.cancel()
        self.image =  placeHolderImage
        self.backgroundColor = backgroundColor

        guard let urlString = urlString, urlString.isValid else { return }
        if let cachedImage = getChachImage(urlString: urlString) {
            self.image = cachedImage
            return
        }

        guard let url = URL(string: urlString) else { return }
        self.url = url
        imageDataTask = URLSession.shared.dataTask(with: url) { [weak self] (data, _, error) in
            guard let self = self else { return }
            guard let data = data, let image = UIImage(data: data), error == nil else { return }
            self.imageDataTask = nil

            if Self.UrlToImageCache == nil {
                Self.UrlToImageCache = NSCache<NSString, UIImage>()
                Self.UrlToImageCache?.countLimit = 100
            }
            Self.UrlToImageCache?.setObject(image, forKey: urlString as NSString)

            if self.url == url {
                DispatchQueue.main.async {
                    if transitionAnimation {
                        UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                            self.image = image
                        }, completion: nil)
                    }
                    else {
                        self.image = image
                    }

                }
            }
        }

        imageDataTask?.resume()
    }
}
