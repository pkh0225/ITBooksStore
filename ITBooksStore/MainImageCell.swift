//
//  MainImageCell.swift
//  pkh0225
//
//  Created by pkh on 2021/07/16.
//

import UIKit

class MainImageCell: UICollectionViewCell, UICollectionViewAdapterCellProtocol {
    static let CLICK_KEY: String = "CLICK_KEY"
    static var itemCount: Int  = 2

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!

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

    }

    func configure(_ data: Any?, subData: Any?, collectionView: UICollectionView, indexPath: IndexPath) {
        guard let data = data as? ITBookListItemData else { return }
        self.data = data
        titleLabel.text = "\(data.title)"
        subtitleLabel.text = "\(data.subtitle)"
        priceLabel.text = "\(data.price)"
        imageView.setUrlImage(data.image, backgroundColor: .imageBackgroundColor)
    }

    func getImageWindowsRect() -> CGRect {
        let rect = imageView.superview?.convert(imageView.frame, to: nil) ?? .zero
        return rect
    }

    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {
        actionClosure?(Self.CLICK_KEY, (imageView.image, indexPath.row))
    }
}
