//
//  DetailViewController.swift
//  ITBooksStore
//
//  Created by pkh on 2021/08/02.
//

import UIKit

private let ANIMATION_DURATUION = 0.2

protocol DetailViewControllerDelegate: AnyObject {
    func didChange(index: Int)
    func getStartRect() -> CGRect
    func willPushStartAnimation()
    func didPushEndAnimation()
    func willPopStartAnimation()
    func didPopEndAnimation()
    func panPopCanelAnimation()
}

/*
    아래로 당기면 아이폰 앨범에서 뒤기로가 애니메이션이 실행됩니다.
    좌우로 Page 기능이 있습니다.(다음 책 정보가 나옵니다.)
 */
class DetailViewController: UIViewController, RouterProtocol {
    static var storyboardName: String = "Main"

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var closeButton: UIButton!

    weak var delegate: DetailViewControllerDelegate?

    lazy var tempImgeView: UIImageView = {
        let v = UIImageView()
        v.clipsToBounds = true
        v.contentMode = .scaleAspectFill
        self.view.addSubview(v)
        return v
    }()
    private let accessQueue = DispatchQueue(label: "accessQueue_ImageDetailViewController", qos: .userInitiated, attributes: .concurrent)
    var dataList = [ITBookListItemData]()
    var nowIndex: Int = 0
    var popAnimator: PopAnimator?
    var defaultImage: UIImage?
    var popAnimationCallBack: VoidClosure?
    var panRecognizer: UIPanGestureRecognizer?
    var beforeSelectedCount: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        popAnimator = PopAnimator(animation: { [weak self] _, toViewController, completion in
            guard let `self` = self else { return }
            self.popAnimation(toViewController: toViewController, completion: completion)
        })

        print("nowIndex: \(nowIndex)")
        makeAdapterData(dataList) { [weak self] adapterData in
            guard let self = self, let adapterData = adapterData else { return }
            self.collectionView.adapterData = adapterData
            self.collectionView.reloadData()
            self.collectionView.layoutIfNeeded()
            self.collectionView.scrollToItem(at: IndexPath(row: self.nowIndex, section: 0), at: .centeredHorizontally, animated: false)
            self.collectionView.setNeedsDisplay()
        }


        collectionView.didScrollCallback { scrollView in
            let x: CGFloat = scrollView.contentOffset.x + (self.collectionView.frame.size.width / 2)
            let horizontalNowPage = Int(x  / self.collectionView.frame.size.width)
            guard self.nowIndex != horizontalNowPage else { return }
            self.nowIndex = horizontalNowPage
            self.delegate?.didChange(index: self.nowIndex)
        }

        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureRecognizer(_:)))
        panRecognizer?.delegate = self
        collectionView.addGestureRecognizer(panRecognizer!)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func onCloseButton(_ sender: UIButton) {
        self.delegate?.didChange(index: self.nowIndex)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func makeAdapterData(_ dataList: [ITBookListItemData], completion: @escaping (_ adapterData: UICollectionViewAdapterData?) -> Void ) {
        accessQueue.async(flags: .barrier) {
            let adapterData = UICollectionViewAdapterData()
            let sectionInfo = UICollectionViewAdapterData.SectionInfo()
            for (idx, subData) in dataList.enumerated() {
                if idx == self.nowIndex {
                    subData.tempImage = self.defaultImage
                }
                let cellInfo = UICollectionViewAdapterData.CellInfo(contentObj: subData,
                                                                    sizeClosure: { [weak self] in
                                                                        guard let self = self else { return .zero }
                                                                        return CGSize(width: self.collectionView.frame.size.w + self.collectionView.trailingConstraint, height: self.collectionView.frame.size.height)
                                                                    },
                                                                    cellType: DetailCell.self) 
                sectionInfo.cells.append(cellInfo)
            }
            adapterData.sectionList.append(sectionInfo)
            DispatchQueue.main.async {
                completion(adapterData)
            }
        }
    }

    func addData(_ addList: [ITBookListItemData]) {
        dataList.append(contentsOf: addList)
        makeAdapterData(dataList) { [weak self] adapterData in
            guard let self = self, let adapterData = adapterData, let cells = adapterData.sectionList[safe: 0]?.cells else { return }
            self.collectionView.adapterData?.sectionList[safe: 0]?.cells.append(contentsOf: cells)
            let end: Int = self.collectionView.adapterData?.sectionList[safe: 0]?.cells.count ?? 0
            let start: Int = end - cells.count
            var insertIndexPath = [IndexPath]()
            for i in start..<end {
                insertIndexPath.append(IndexPath(item: i, section: 0))
            }
            self.collectionView.insertItems(at: insertIndexPath)
        }
    }

    func reloadData() {
        collectionView.reloadData()
    }
}


// MARK: - Push, Pop Animation
extension DetailViewController: NavigationAnimatorAble {
    var pushAnimation: PushAnimator? {
        let animator = PushAnimator { [weak self] fromViewController, _, completion in
            guard let `self` = self else { return }
            self.pushAnimation(fromViewController: fromViewController, completion: completion)
        }
        return animator
    }

    var popAnimation: PopAnimator? {
        return self.popAnimator
    }

    func getImageCenter() -> CGPoint {
        var rect = self.collectionView.frame
        rect.w += collectionView.trailingConstraint // 이미지 오늘쪽 여백을 주기위해 마진값이 들어 있음
        return rect.center
    }

    func getImageSize() -> CGRect {
        var topSafeArea: CGFloat
        if #available(iOS 11.0, *) {
            topSafeArea = view.safeAreaInsets.top
        } else {
            topSafeArea = topLayoutGuide.length
        }


        let cell = DetailCell.fromXib(cache: true)
        let newSize = tempImgeView.image?.size.ratioSize(setWidth: self.view.frame.size.width - cell.imageView.leadingConstraint - cell.imageView.trailingConstraint) ?? .zero
        return CGRect(x: cell.imageView.leadingConstraint, y: cell.imageView.trailingConstraint + topSafeArea, width: newSize.width, height: newSize.height)
    }

    func pushAnimation(fromViewController: UIViewController, completion: @escaping () -> Void) {
        self.delegate?.willPushStartAnimation()
        view.backgroundColor = UIColor.clear
        view.layoutIfNeeded()
        closeButton.alpha = 0
        tempImgeView.isHidden = false
        tempImgeView.image = defaultImage
        tempImgeView.frame = self.delegate?.getStartRect() ?? .zero
        collectionView.isHidden = true
        let rect = self.getImageSize()

        UIView.animate(withDuration:ANIMATION_DURATUION, delay: 0, options: .curveEaseInOut, animations: {
            self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            self.tempImgeView.frame = rect
            self.closeButton.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { _ in
            self.tempImgeView.isHidden = true
            self.collectionView.isHidden = false
            self.delegate?.didPushEndAnimation()
            completion()
        }
    }

    func popAnimation(toViewController: UIViewController, completion: @escaping () -> Void) {
        if preferredInterfaceOrientationForPresentation != .portrait {
            completion()
            return
        }
        guard let cell = collectionView.visibleCells.first as? DetailCell  else { return }
        let rect = cell.getImageWindowsRect()


        self.delegate?.willPopStartAnimation()
        self.tempImgeView.image = cell.imageView.image

        if popAnimator?.interactionController == nil {
            collectionView.isHidden = true
            tempImgeView.isHidden = false

            tempImgeView.frame = rect
            view.layoutIfNeeded()

            UIView.animate(withDuration: ANIMATION_DURATUION, delay: 0, options: .curveEaseInOut, animations: {
                self.view.backgroundColor = UIColor.clear
                self.tempImgeView.frame = self.delegate?.getStartRect() ?? .zero
                self.closeButton.alpha = 0
                self.view.layoutIfNeeded()
            }) { _ in
                self.collectionView.isHidden = false
                self.tempImgeView.isHidden = true
                self.delegate?.didPopEndAnimation()
                completion()
            }
        }
        else {
            popAnimationCallBack = completion
            collectionView.isHidden = true
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.view.backgroundColor = UIColor.clear
                self.closeButton.alpha = 0
                self.view.layoutIfNeeded()
            }) { _ in
            }
        }
    }
}

// MARK: - Gesture
extension DetailViewController {
    @objc func panGestureRecognizer(_ recognizer: UIPanGestureRecognizer) {
        guard let cell = collectionView.visibleCells.first as? DetailCell, let scrollView = cell.scrollView else { return }

        let velocity: CGPoint = recognizer.velocity(in: recognizer.view)
        let isVerticalGesture: Bool = abs(Float(velocity.y)) > abs(Float(velocity.x))
        if recognizer.state == .began {
            if scrollView.zoomScale != 1.0 || isVerticalGesture == false || (velocity.y) < 0 {
                return
            }
//            self.delegate?.didChange(index: self.nowIndex)
            self.delegate?.willPopStartAnimation()
            self.tempImgeView.image = cell.imageView.image
            if (navigationController?.viewControllers.count ?? 0) > 1 {
                popAnimator?.interactionController = UIPercentDrivenInteractiveTransition()
                navigationController?.popViewController(animated: true)
            }
            tempImgeView.isHidden = false
            guard let cell = collectionView.visibleCells.first as? DetailCell  else { return }
            tempImgeView.frame = cell.getImageWindowsRect()
        }
        else if recognizer.state == .changed {
            if popAnimator?.interactionController == nil {
                return
            }
            let translation: CGPoint = recognizer.translation(in: view)
            let d: CGFloat = (translation.y) / view.bounds.height
            popAnimator?.interactionController?.update(d)
            let rate: CGFloat = (0.5 - d) + 0.5
            var point: CGPoint = recognizer.translation(in: view.window)
            point.x += self.view.center.x
            point.y += self.view.center.y
            let newSize: CGSize = tempImgeView.image?.size.ratioSize(setWidth: self.view.frame.size.width) ?? .zero
            tempImgeView.frame.size.width = min(newSize.width, newSize.width * rate)
            tempImgeView.frame.size.height = min(newSize.height, newSize.height * rate)
            tempImgeView.center = point
        }
        else if recognizer.state == .ended {
            if popAnimator?.interactionController == nil {
                return
            }
            if (velocity.y) > 25 {
                panAnimationFinish()
            }
            else if (velocity.y) < -25 {
                panAnimationCancelFinish()
            }
            else {
                if tempImgeView.center.y > scrollView.frame.size.height / 2 {
                    panAnimationFinish()
                }
                else {
                    panAnimationCancelFinish()
                }
            }
            popAnimator?.interactionController = nil
        }
        else {
            panAnimationCancelFinish()
        }
    }
    func panAnimationFinish() {
        UIView.animate(withDuration: ANIMATION_DURATUION, animations: {
            self.popAnimator?.interactionController?.finish()
            self.tempImgeView.frame = self.delegate?.getStartRect() ?? .zero
        }) { _ in
            self.delegate?.didPopEndAnimation()
            self.popAnimationCallBack?()
        }
    }
    func panAnimationCancelFinish() {
        let newSize: CGSize = self.tempImgeView.image?.size.ratioSize(setWidth: self.view.frame.size.width) ?? .zero
        let center: CGPoint = self.view.center
        UIView.animate(withDuration: 0.2, animations: {
            self.popAnimator?.interactionController?.cancel()
            self.tempImgeView.frame = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            self.tempImgeView.center = center
        }) { _ in
            self.collectionView.isHidden = false
            self.tempImgeView.isHidden = true
            self.popAnimationCallBack?()
            self.delegate?.panPopCanelAnimation()
        }
    }
}

extension DetailViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
