//
//  ViewController.swift
//  ITBooksStore
//
//  Created by pkh on 2021/07/31.
//

import UIKit

/*

    여기서 사용된 모든 라이브러리는 모두 제가 예전에 만든것이고 일부는 제 GitHub(https://github.com/pkh0225) 에 공개 해 놓은것들도 있습니다.

 */
class MainViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    lazy var indicatorBackView: UIView = {
        let v = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        self.view.addSubview(v)
        v.centerInSuperView()
        v.autoresizingMask = []
        v.backgroundColor = UIColor(hex: 0x000000, alpha: 0.7)
        v.cornerRadius = 10
        return v
    }()

    lazy var indicatorView: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .whiteLarge)
        indicatorBackView.addSubview(i)
        i.centerInSuperView()
        i.autoresizingMask = []
        return i
    }()

    private let accessQueue = DispatchQueue(label: "accessQueue_MainViewController", qos: .userInitiated, attributes: .concurrent)
    var pageIndex: Int = 0
    var dataList = [ITBookListItemData]()
    var urlTask: URLSessionDataTask?

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManager.shared.mainNavigation = self.navigationController
        setSearchbarAccessoryView()
        setup()

        DispatchQueue.main.async {
            self.searchBar.becomeFirstResponder()
        }
    }

    func setup() {
        self.pageIndex = 0
        self.collectionView.adapterHasNext = true
    }

    func setSearchbarAccessoryView() {
        let aView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.w, height: 45))
        aView.backgroundColor = UIColor(hex: 0xf0f0f0)
        aView.borderWidth = 1
        aView.borderColor = .black
        let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 35))
        aView.addSubview(btn)
        btn.setTitle("닫기", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        btn.setTitleColor(.black, for: .normal)
        btn.cornerRadius = 5
        btn.borderWidth = 1
        btn.borderColor = .darkGray
        btn.x = aView.w - btn.w - 10
        btn.centerYInSuperView()
        btn.addAction(for: .touchUpInside) { [weak self] button in
            guard let self = self else { return }
            self.searchBar.resignFirstResponder()
        }
        btn.autoresizingMask = [.flexibleRightMargin]

        searchBar.inputAccessoryView = aView
    }



    func startIndicatorView() {
        indicatorBackView.isHidden = false
        indicatorView.startAnimating()
    }

    func stopIndicatorView() {
        indicatorBackView.isHidden = true
        indicatorView.stopAnimating()
    }


    func requestSearchData(_ query: String) {
        pageIndex += 1
        if pageIndex == 1 {
            startIndicatorView()
        }

        urlTask = ITBookListData.requestSearchData(query: query, pageIndex: pageIndex) { requestData in
            guard requestData.books.count > 0 else {
                if self.pageIndex == 1 {
                    self.collectionView.isHidden = true
                }
                self.collectionView.adapterHasNext = false
                self.stopIndicatorView()
                return
            }

            self.makeAdapterData(requestData) { [weak self] adapterData in
                guard let self = self, let adapterData = adapterData else { return }
                if self.pageIndex == 1 {
                    self.collectionView.contentOffset = .zero
                }

                self.collectionView.adapterHasNext = true
                self.collectionView.adapterRequestNextClosure = { [weak self] in
                    guard let `self` = self else { return }
                    self.requestSearchData(query)
                }
                self.setImageDataList(requestData)
                self.setCollectionViewData(adapterData)
                self.stopIndicatorView()
            }
        }
    }

    func makeAdapterData(_ data: ITBookListData, completion: @escaping (_ adapterData: UICollectionViewAdapterData?) -> Void ) {
        accessQueue.async(flags: .barrier) {
            let adapterData = UICollectionViewAdapterData()
            let sectionInfo = UICollectionViewAdapterData.SectionInfo()
            for subData in data.books {
                let cellInfo = UICollectionViewAdapterData.CellInfo(contentObj: subData,
                                                                    cellType: MainImageCell.self) { [weak self]  ( name, data) in
                    guard let self = self else { return }

                    if name == MainImageCell.CLICK_KEY, let data = data as? ITBookListItemData {
                        self.showDetail(data)
                    }

                }
                sectionInfo.cells.append(cellInfo)
            }
            adapterData.sectionList.append(sectionInfo)
            DispatchQueue.main.async {
                completion(adapterData)
            }
        }
    }

    func setImageDataList(_ data: ITBookListData) {
        if self.pageIndex == 1 {
            self.dataList = data.books
        }
        else {
            self.dataList.append(contentsOf: data.books)
//            if let vc = self.navigationController?.viewControllers.last as? ImageDetailViewController {
//                vc.addData(data.books)
//            }
        }
    }

    func setCollectionViewData(_ adapterData: UICollectionViewAdapterData?) {
        guard let adapterData = adapterData else { return }

        if self.pageIndex == 1 {
            self.collectionView.adapterData = adapterData
            self.collectionView.reloadData()
        }
        else if let cells = adapterData.sectionList[safe: 0]?.cells {
            self.collectionView.adapterData?.sectionList[safe: 0]?.cells.append(contentsOf: cells)
            let end: Int = self.collectionView.adapterData?.sectionList[safe: 0]?.cells.count ?? 0
            let start: Int = end - cells.count
            var insertIndexPath = [IndexPath]()
            for i in start..<end {
                insertIndexPath.append(IndexPath(item: i, section: 0))
            }
            self.collectionView.insertItems(at: insertIndexPath)
        }
        self.collectionView.isHidden = false
    }

    func showDetail(_ data: ITBookListItemData) {
        searchBar.resignFirstResponder()
//        self.showDetailPageIndex = data.index
//        let vc = ImageDetailViewController.pushViewController()
//        vc.delegate = self
//        vc.imageDataList = self.imageDataList
//        vc.nowIndex = data.index
//        vc.defaultImage = data.image
    }
}

//MARK: - UISearchBarDelegate
extension MainViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        urlTask?.cancel()
        if searchText.isValid {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.onSearch), object: nil)
            self.perform(#selector(self.onSearch), with: nil, afterDelay: 0.2)
        }
    }

    @objc func onSearch() {
        guard let query = searchBar.text, query.isValid else { return }
        setup()
        requestSearchData(query)
    }
}
