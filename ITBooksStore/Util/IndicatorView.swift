//
//  IndicatorView.swift
//  ITBooksStore
//
//  Created by pkh on 2021/08/02.
//

import UIKit

class IndicatorView: UIView {

    var activityIndicatorView: UIActivityIndicatorView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    required init(superView: UIView) {
        super.init(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        superView.addSubview(self)
        self.centerInSuperView()
        self.autoresizingMask = []
        self.backgroundColor = UIColor(hex: 0x000000, alpha: 0.7)
        self.cornerRadius = 10

        setup()
    }

    func setup() {
        activityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
        self.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperView()
        activityIndicatorView.autoresizingMask = []
    }

    func startIndicatorView() {
        self.isHidden = false
        activityIndicatorView.startAnimating()
    }

    func stopIndicatorView() {
        self.isHidden = true
        activityIndicatorView.stopAnimating()
    }
}
