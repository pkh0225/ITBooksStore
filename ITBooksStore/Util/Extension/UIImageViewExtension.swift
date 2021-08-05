//
//  UIImageViewExtension.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import Foundation
import UIKit

extension UIImageView {
    private struct AssociatedKeys {
        static var imageDataTask: UInt8 = 0
        static var url: UInt8 = 0
        static var accessQueue: UInt = 0
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

    private var urlString: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.url) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.url, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var accessQueue: DispatchQueue? {
        get {
            if let q = objc_getAssociatedObject(self, &AssociatedKeys.imageDataTask) as? DispatchQueue {
                return q
            }
            let q =  DispatchQueue(label: "accessQueue_UIImageView", qos: .userInitiated, attributes: .concurrent)
            objc_setAssociatedObject(self, &AssociatedKeys.url, q, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return q

        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.url, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func getMemoryCaachImage(urlString: String?) -> UIImage? {
        guard let urlString = urlString, urlString.isValid else { return  nil }
        return Self.UrlToImageCache?.object(forKey: urlString as NSString)
    }

    func saveMemoryCacheImage(urlString: String?, image: UIImage?) {
        guard let urlString = urlString, let image = image else { return }
        if Self.UrlToImageCache == nil {
            Self.UrlToImageCache = NSCache<NSString, UIImage>()
            Self.UrlToImageCache?.countLimit = 100
            Self.UrlToImageCache?.totalCostLimit = 50 * 1024 * 1024;
        }
        if Self.UrlToImageCache?.object(forKey: urlString as NSString) == nil {
            Self.UrlToImageCache?.setObject(image, forKey: urlString as NSString)
        }
    }

    func momoryCacheClear() {
        Self.UrlToImageCache?.removeAllObjects()
    }

    func getFileName(urlString: String?) -> String? {
        guard let urlString = urlString, let url = URL(string: urlString) else { return nil }
        var fileName: String = ""
        for (idx,path) in url.pathComponents.enumerated() {
            guard idx > 0 else { continue }
            fileName += "_\(path)"
        }
        return fileName
    }

    func saveDiskCagheImage(urlString: String?, image: UIImage) {
        guard let urlString = urlString else { return }
        self.accessQueue?.async(flags: .barrier) {
            guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else { return }

            guard let fileName = self.getFileName(urlString: urlString) else { return }
            var filePath = URL(fileURLWithPath: path)
            filePath.appendPathComponent("image")


            if !FileManager.default.fileExists(atPath: filePath.path) {
                try? FileManager.default.createDirectory(atPath: filePath.path, withIntermediateDirectories: false, attributes: nil)
            }

            filePath.appendPathComponent(fileName)
            guard !FileManager.default.fileExists(atPath: filePath.path) else { return }
            FileManager.default.createFile(atPath: filePath.path, contents: image.jpegData(compressionQuality: 1), attributes: nil)
        }
    }

    func getDiskCacheImage(urlString: String?, completion: @escaping (Result<UIImage?, NSError>) -> Void) {
        self.accessQueue?.async(flags: .barrier) {
            guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
                completion((.failure(NSError(domain: "path Directories error", code: -2000, userInfo: nil))))
                return
            }

            guard let fileName = self.getFileName(urlString: urlString) else {
                completion((.failure(NSError(domain: "get file name error", code: -3000, userInfo: nil))))
                return
            }

            var filePath = URL(fileURLWithPath: path)
            filePath.appendPathComponent("image")
            filePath.appendPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: filePath.path) else {
                completion((.failure(NSError(domain: "file path error", code: -4000, userInfo: nil))))
                return
            }

            guard let imageData = try? Data(contentsOf: filePath) else {
                completion((.failure(NSError(domain: "imageData error", code: -5000, userInfo: nil))))
                return
            }

            guard let image = UIImage(data: imageData) else {
                completion((.failure(NSError(domain: "data to convert error", code: -6000, userInfo: nil))))
                return
            }

            completion((.success(image)))
        }
    }

    func diskCacheClear() {
        guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else { return }
        var filePath = URL(fileURLWithPath: path)
        filePath.appendPathComponent("image")
        try? FileManager.default.removeItem(at: filePath)
    }

    func setUrlImage(_ urlString: String?, placeHolderImage: UIImage? = nil, backgroundColor: UIColor? = nil, transitionAnimation: Bool = true, cache: Bool = true) {
        imageDataTask?.cancel()
        self.urlString = urlString

        self.image =  placeHolderImage
        self.backgroundColor = backgroundColor
        
        guard let urlString = urlString, urlString.isValid else { return }
        guard let url = URL(string: urlString) else { return }

        var urlRequest = URLRequest(url: url)
        if cache, let eTag = UserDefaults.standard.object(forKey: "Etag_\(urlString)") as? String {
            urlRequest.addValue(eTag, forHTTPHeaderField: "If-None-Match")
        }

        imageDataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            guard let self = self else { return }
            self.imageDataTask = nil

            if let _ = error {
//                print("iamge download error: " + error.localizedDescription + "\n")
                return
            }
            else if let response = response as? HTTPURLResponse {
                // 변경되지 않음
                if cache, response.statusCode == 304 {
//                    print("변경되지 않음")
                    if let image = self.getMemoryCaachImage(urlString: urlString) {
                        DispatchQueue.main.sync {
                            self.image = image
                            self.backgroundColor = .none
                        }
//                        print("image memory Cache: \(urlString)")
                        return
                    }

                    self.getDiskCacheImage(urlString: urlString) { [weak self] result in
                        guard let self = self else { return }

                        switch result {
                        case .success(let image):
                            DispatchQueue.main.sync {
                                self.image = image
                                self.backgroundColor = .none
                            }
                            self.saveMemoryCacheImage(urlString: urlString, image: image)
//                            print("image disk Cache: \(urlString)")
                        case .failure(_):
                //            print("getDiskCacheImage error : \(error)")
//                            print("not cache retry")
                            DispatchQueue.main.async {
                                self.setUrlImage(urlString, placeHolderImage: placeHolderImage, backgroundColor: backgroundColor, transitionAnimation: transitionAnimation, cache: false)
                            }
                        }
                    }
                }
                else if response.statusCode == 200, let data = data, let image = UIImage(data: data) {
                    if self.urlString == urlString {
                        DispatchQueue.main.sync {
                            if transitionAnimation {
                                UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve], animations: {
                                    self.image = image
                                    self.backgroundColor = .none
                                }, completion: nil)
                            }
                            else {
                                self.image = image
                                self.backgroundColor = .none
                            }
                        }
                    }

                    if let etag = response.allHeaderFields["Etag"] as? String {
                        UserDefaults.standard.setValue(etag, forKey: "Etag_\(urlString)")
                    }

                    self.saveMemoryCacheImage(urlString: urlString, image: image)
                    self.saveDiskCagheImage(urlString: urlString, image: image)
                }
                else {
                    print("response.statusCode: \(response.statusCode)")
                }
            }


        }

        imageDataTask?.resume()
    }
}
