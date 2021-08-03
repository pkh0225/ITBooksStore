//
//  DetailCell.swift
//  pkh0225
//
//  Created by pkh on 2021/08/02.
//

import UIKit

/*
    Cell 에서 롱터시시 디버깅모드가 실행됩니다.(JSON Data를 볼수 있고 검색 및 수정 후 저장 기능이 지원합니다.)
 */
class DetailCell: UICollectionViewCell, UICollectionViewAdapterCellProtocol {
    static let SELECTED_ADD_KEY: String = "SELECTED_ADD_KEY"
    static let SELECTED_REMOVE_KEY: String = "SELECTED_REMOVE_KEY"
    static var itemCount: Int = 1


    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titieLabel: UILabel!
    @IBOutlet weak var subTitieLabel: UILabel!
    @IBOutlet weak var authorsLabel: UILabel!
    @IBOutlet weak var publisherLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var pagesLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!

    lazy var indicatorView: IndicatorView = {
        let i = IndicatorView(superView: self)
        i.bringSubviewToFront(self)
        return i
    }()


    var actionClosure: ActionClosure?
    var data: ITBookListItemData?
    var detailData: ITBookDetailData?
    var urlTask: URLSessionDataTask?
    var isDebuging: Bool = false

    override func awakeFromNib() {
        super.awakeFromNib()

        if PKHParser.isDebuging {
            self.addLongPressGesture { [weak self] recognizer in
                guard let self = self else { return }
                if recognizer.state == .began {
                    //                    print(" ** DebugData LogPreeGesture **")
                    let vc = DebugDataViewController.pushViewController()
                    if let data = self.detailData {
                        vc.debugDatas = [data]
                    }
                    else if let data = self.data {
                        vc.debugDatas = [data]
                    }

                    vc.editCallBack = { [weak self] (_, dic) in
                        guard let self = self else { return }
                        guard let dic = dic else { return }
                        guard let debugData = self.detailData else { return }
                        self.isDebuging = true
                        debugData.setDataToDic(dic: dic, anyData: debugData)
                        self.getCollectionView()?.reloadData()
                    }
                }
            }

        }

        urlLabel.isUserInteractionEnabled = true
        let btn = UIButton(frame: urlLabel.bounds)
        urlLabel.addSubviewResizingMask(btn)
        btn.addAction(for: .touchUpInside) { [weak self] button in
            guard let self = self else { return }
            guard let url = URL(string: self.detailData?.url ?? "") else { return }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                })
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }

    func configure(_ data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {
        guard let data = data as? ITBookListItemData else { return }
        self.data = data
        scrollView.zoomScale = 1.0
        imageView.setUrlImage(data.image, placeHolderImage: data.tempImage, backgroundColor: .black)
        data.tempImage = nil

        titieLabel.text = nil
        subTitieLabel.text = nil
        authorsLabel.text = nil
        publisherLabel.text = nil
        languageLabel.text = nil
        pagesLabel.text = nil
        yearLabel.text = nil
        ratingLabel.text = nil
        priceLabel.text = nil
        urlLabel.attributedText = nil
        descLabel.text = nil

        if isDebuging, let requestData = self.detailData {

            if data.image != requestData.image {
                self.imageView.setUrlImage(data.image, backgroundColor: .black)
            }

            self.titieLabel.text = requestData.title
            self.subTitieLabel.text = requestData.subtitle
            self.authorsLabel.text = "authors : \(requestData.authors)"
            self.publisherLabel.text = "publisher : \(requestData.publisher)"
            self.languageLabel.text = "language : \(requestData.language)"
            self.pagesLabel.text = "isbn10 : \(requestData.isbn10)"
            self.yearLabel.text = "isbn13 : \(requestData.isbn13)"
            self.ratingLabel.text = "year : \(requestData.year)"
            self.priceLabel.text = "price : \(requestData.price)"
            self.urlLabel.attributedText = requestData.url.underLine()
            self.descLabel.text = requestData.desc

        }
        else {
            indicatorView.startIndicatorView()
            urlTask?.cancel()
            urlTask = ITBookDetailData.request(isbn13: data.isbn13, completion: { [weak self] requestData in
                guard let self = self else { return }
                //            print(data)
//                print(requestData)
                self.detailData = requestData
                if data.image != requestData.image {
                    self.imageView.setUrlImage(data.image, backgroundColor: .black)
                }

                self.titieLabel.text = requestData.title
                self.subTitieLabel.text = requestData.subtitle
                self.authorsLabel.text = "authors : \(requestData.authors)"
                self.publisherLabel.text = "publisher : \(requestData.publisher)"
                self.languageLabel.text = "language : \(requestData.language)"
                self.pagesLabel.text = "isbn10 : \(requestData.isbn10)"
                self.yearLabel.text = "isbn13 : \(requestData.isbn13)"
                self.ratingLabel.text = "year : \(requestData.year)"
                self.priceLabel.text = "price : \(requestData.price)"
                self.urlLabel.attributedText = requestData.url.underLine()
                self.descLabel.text = requestData.desc

                self.indicatorView.stopIndicatorView()
            })

        }
        isDebuging = false

    }

    func getImageWindowsRect() -> CGRect {
        let rect = imageView.superview?.convert(imageView.frame, to: nil) ?? .zero
        return rect
    }

    func getCollectionView() -> UICollectionView? {
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if responder is UICollectionView {
                break
            }
        }
        return responder as? UICollectionView
    }
}

