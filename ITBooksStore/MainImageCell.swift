//
//  MainImageCell.swift
//  pkh0225
//
//  Created by pkh on 2021/07/16.
//

import UIKit

/*
    1. Cell 에서 롱터시시 디버깅모드가 실행됩니다.(JSON Data를 볼수 있고 검색 및 수정 후 저장 기능이 지원합니다.)
 */
class MainImageCell: UICollectionViewCell, UICollectionViewAdapterCellProtocol {
    static let CLICK_KEY: String = "CLICK_KEY"
    static var itemCount: Int  = 2

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var countLabe: UILabel!

    var actionClosure: ActionClosure? = nil
    var data: ITBookListItemData?

    static func getSize(_ data: Any?, width: CGFloat, collectionView: UICollectionView, indexPath: IndexPath) -> CGSize {
        let cell = Self.fromXib(cache: true)
        var height = cell.h - cell.imageView.h

        // 그려지는 아이템 높이를 가로 길이ㅔ 맞게 다시 계산한다.
        height += cell.imageView.size.ratioHeight(setWidth: width - cell.imageView.leadingConstraint - cell.imageView.trailingConstraint)

        return CGSize(width: width, height: height)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        if PKHParser.isDebuging {
            self.addLongPressGesture { [weak self] recognizer in
                guard let self = self else { return }
                guard let debugData = self.data else { return }
                if recognizer.state == .began {
                    //                    print(" ** DebugData LogPreeGesture **")
                    let vc = DebugDataViewController.pushViewController()
                    vc.debugDatas = [debugData]
                    vc.editCallBack = { [weak self] (_, dic) in
                        guard let self = self else { return }
                        guard let dic = dic else { return }
                        guard let debugData = self.data else { return }

                        debugData.setDataToDic(dic: dic, anyData: debugData)
                        self.getCollectionView()?.reloadData()
                    }
                }
            }
        }
    }

    func configure(_ data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {
        guard let data = data as? ITBookListItemData else { return }
        self.data = data
        titleLabel.text = "\(data.title)"
        subtitleLabel.text = "\(data.subtitle)"
        priceLabel.text = "\(data.price)"
        imageView.setUrlImage(data.image, backgroundColor: .imageBackgroundColor)

        countLabe.text = "\(indexPath.row)"
    }

    func getImageWindowsRect() -> CGRect {
        let rect = imageView.superview?.convert(imageView.frame, to: nil) ?? .zero
        return rect
    }

    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {
        actionClosure?(Self.CLICK_KEY, (imageView.image, indexPath.row))
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
