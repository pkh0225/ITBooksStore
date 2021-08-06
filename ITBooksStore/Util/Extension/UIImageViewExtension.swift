//
//  UIImageViewExtension.swift
//  pkh0225
//
//  Created by pkh on 2021/07/11.
//

import Foundation
import UIKit

func gcd_main_safe(_ block: @escaping () -> Void) {
    if Thread.isMainThread {
        block()
    }
    else {
        DispatchQueue.main.async(execute: block)
    }
}


extension UIImageView {
    private struct AssociatedKeys {
        static var imageDataTask: UInt8 = 0
        static var url: UInt8 = 0
        static var accessQueue: UInt = 0
    }

    enum CacheType {
        case none
        case memory
        case disk
    }

    private static var UrlToImageCache: NSCache<NSString, UIImage>?
    private static var accessQueue: DispatchQueue? {
        get {
            if let q = objc_getAssociatedObject(self, &AssociatedKeys.imageDataTask) as? DispatchQueue {
                return q
            }
            let queue =  DispatchQueue(label: "accessQueue_UIImageView", qos: .userInitiated, attributes: .concurrent)
            objc_setAssociatedObject(self, &AssociatedKeys.url, queue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return queue

        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.url, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var imageDataTask: URLSessionDataTask? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.imageDataTask) as? URLSessionDataTask
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.imageDataTask, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func setUrlImage(_ urlString: String?, placeHolderImage: UIImage? = nil, backgroundColor: UIColor? = nil, transitionAnimation: Bool = true, cache: Bool = true, isEtage: Bool = true) {
        imageDataTask?.cancel()
        imageDataTask = nil
        guard let urlString = urlString, urlString.isValid, let url = URL(string: urlString) else {
            self.image =  placeHolderImage
            self.backgroundColor = backgroundColor
            return
        }

        if cache, !isEtage {
            getCacheImage(urlString: urlString) { cacheType in
                if cacheType == .none {
                    gcd_main_safe {
                        self.setUrlImage(urlString, placeHolderImage: placeHolderImage, backgroundColor: backgroundColor, transitionAnimation: transitionAnimation, cache: false, isEtage: false)
                    }
                }
            }
        }
        else {
            self.image =  placeHolderImage
            self.backgroundColor = backgroundColor

            var urlRequest = URLRequest(url: url)
            if isEtage, let eTag = UserDefaults.standard.object(forKey: "Etag_\(urlString)") as? String {
                urlRequest.addValue(eTag, forHTTPHeaderField: "If-None-Match")
            }

            self.imageDataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
                guard let self = self else { return }
                self.imageDataTask = nil

                if let _ = error {
                    //                print("iamge download error: " + error.localizedDescription + "\n")
                    return
                }
                else if let response = response as? HTTPURLResponse {
                    // 변경되지 않음
                    if response.statusCode == 304 {
//                        print("not change")
                        self.getCacheImage(urlString: urlString) { cacheType in
                            if cacheType == .none {
                                gcd_main_safe {
//                                    print("not cache retry")
                                    self.setUrlImage(urlString, placeHolderImage: placeHolderImage, backgroundColor: backgroundColor, transitionAnimation: transitionAnimation, cache: false, isEtage: false)
                                }
                            }
                        }
                    }
                    else if response.statusCode == 200, let data = data, let image = UIImage(data: data) {
                        gcd_main_safe {
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

                        if let etag = response.allHeaderFields["Etag"] as? String {
                            UserDefaults.standard.setValue(etag, forKey: "Etag_\(urlString)")
                        }
                        self.saveCacheImage(urlString: urlString, image: image)
                    }
                    else {
                        print("response.statusCode: \(response.statusCode)")
                    }
                }
            }

            self.imageDataTask?.resume()
        }
    }


    func getMemoryCache(urlString: String?) -> UIImage? {
        guard let urlString = urlString, urlString.isValid else { return  nil }
        return Self.UrlToImageCache?.object(forKey: urlString as NSString)
    }

    func saveMemoryCache(urlString: String?, image: UIImage?) {
        guard let urlString = urlString, let image = image else { return }
        if Self.UrlToImageCache == nil {
            Self.UrlToImageCache = NSCache<NSString, UIImage>()
            Self.UrlToImageCache?.countLimit = 100
            Self.UrlToImageCache?.totalCostLimit = 100 * 1024 * 1024;
        }
        Self.UrlToImageCache?.setObject(image, forKey: urlString as NSString)
    }

    func removeMemoryCache(urlString: String?) {
        guard let urlString = urlString  else { return }
        Self.UrlToImageCache?.removeObject(forKey: urlString as NSString)
    }

    static func momoryCacheClear() {
        Self.UrlToImageCache?.removeAllObjects()
    }

    func getFileName(urlString: String?) -> String? {
        guard let urlString = urlString, let urlComponents = URLComponents(string: urlString) else { return nil }
        guard let url = urlComponents.url else { return nil }
        var fileName: String = ""
        for (idx,path) in url.pathComponents.enumerated() {
            guard idx > 0 else { continue }
            fileName += "_\(path)"
        }

        if let queryItems = urlComponents.queryItems {
            for item in queryItems {
                fileName += "_\(item)"
            }
        }

        return fileName
    }

    func saveDiskCache(urlString: String?, image: UIImage) {
        guard let urlString = urlString else { return }

        guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else { return }

        guard let fileName = self.getFileName(urlString: urlString) else { return }
        var filePath = URL(fileURLWithPath: path)
        filePath.appendPathComponent("image")
        if !FileManager.default.fileExists(atPath: filePath.path) {
            try? FileManager.default.createDirectory(atPath: filePath.path, withIntermediateDirectories: false, attributes: nil)
        }

        filePath.appendPathComponent(fileName)
//        guard !FileManager.default.fileExists(atPath: filePath.path) else { return }
        FileManager.default.createFile(atPath: filePath.path, contents: image.jpegData(compressionQuality: 1), attributes: nil)
    }

    func removeDiskCache(urlString: String?) {
        guard let urlString = urlString else { return }

        guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else { return }

        guard let fileName = self.getFileName(urlString: urlString) else { return }
        var filePath = URL(fileURLWithPath: path)
        filePath.appendPathComponent("image")
        if !FileManager.default.fileExists(atPath: filePath.path) {
            try? FileManager.default.createDirectory(atPath: filePath.path, withIntermediateDirectories: false, attributes: nil)
        }

        filePath.appendPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: filePath.path) else { return }
        try? FileManager.default.removeItem(atPath: filePath.path)
    }

    func getDiskCache(urlString: String?) -> Result<UIImage?, NSError> {
        guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return (.failure(NSError(domain: "path Directories error", code: -2000, userInfo: nil)))
        }

        guard let fileName = self.getFileName(urlString: urlString) else {
            return (.failure(NSError(domain: "get file name error", code: -3000, userInfo: nil)))
        }

        var filePath = URL(fileURLWithPath: path)
        filePath.appendPathComponent("image")
        filePath.appendPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return (.failure(NSError(domain: "file path error", code: -4000, userInfo: nil)))
        }

        guard let imageData = try? Data(contentsOf: filePath) else {
            return (.failure(NSError(domain: "imageData error", code: -5000, userInfo: nil)))
        }

        guard let image = UIImage(data: imageData) else {
            return (.failure(NSError(domain: "data to convert error", code: -6000, userInfo: nil)))
        }

        return (.success(image))
    }

    static func diskCacheClear() {
        guard let path = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else { return }
        var filePath = URL(fileURLWithPath: path)
        filePath.appendPathComponent("image")
        try? FileManager.default.removeItem(at: filePath)
    }

    func getCacheImage(urlString: String, completion: @escaping (CacheType) -> Void) {
        if let image = self.getMemoryCache(urlString: urlString) {
//            print("image memory Cache: \(urlString)")
            gcd_main_safe {
                self.image = image
                self.backgroundColor = .none
            }
            return completion(.memory)
        }
        else {
            Self.accessQueue?.sync() {
                let result = self.getDiskCache(urlString: urlString)
                switch result {
                case .success(let image):
//                    print("image disk Cache: \(urlString)")
                    gcd_main_safe {
                        self.image = image
                        self.backgroundColor = .none
                    }
                    self.saveMemoryCache(urlString: urlString, image: image)
                    return completion(.disk)

                case .failure(_):
    //                            print("getDiskCacheImage error : \(error)")
                    return completion(.none)
                }
            }
        }
    }

    func saveCacheImage(urlString: String?, image: UIImage) {
        self.saveMemoryCache(urlString: urlString, image: image)
        Self.accessQueue?.async(flags: .barrier) {
            self.saveDiskCache(urlString: urlString, image: image)
        }
    }

    func removeCacheImage(urlString: String?) {
        self.removeMemoryCache(urlString: urlString)
        Self.accessQueue?.async(flags: .barrier) {
            self.removeDiskCache(urlString: urlString)
        }
    }

    static func getImageCacheCapacityAsMB() -> Int64 {
        guard var cacheUrlString = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else { return 0 }
        cacheUrlString += "/image"
        var folderSize = 0
        if FileManager.default.fileExists(atPath: cacheUrlString) {
            do {
                let attribute = try FileManager.default.attributesOfItem(atPath: cacheUrlString)
                folderSize += attribute[FileAttributeKey.size] as! Int
                let filelist = try FileManager.default.contentsOfDirectory(atPath: cacheUrlString)
                filelist.forEach { file in
                    let tmp = cacheUrlString.appending("/\(file)")
                    do {
                        let attribute = try FileManager.default.attributesOfItem(atPath: tmp)
                        folderSize += attribute[FileAttributeKey.size] as! Int

                    }
                    catch let error as NSError {
                        print("\(#function) error: \(error)")

                    }

                }

            }
            catch let error as NSError {
                print("\(#function) error: \(error)")

            }

        }
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = .useMB
        byteCountFormatter.countStyle = .file

        let folderSizeToDisplay = byteCountFormatter.string(fromByteCount: Int64(folderSize))
        print( folderSize == 0 ? "Image Cache 0 MB" : "Image Cache \(folderSizeToDisplay)" )

        return Int64(folderSize) / 1000000
    }


    /// 제한 용량 MB 로 제한
    @discardableResult
    static func checkDiskCacheAndRemove(totalCostLimit: Int64) -> Bool {
        if getImageCacheCapacityAsMB() > totalCostLimit {
            diskCacheClear()
            return true
        }
        return false
    }

}
