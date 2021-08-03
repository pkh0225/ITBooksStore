//
//  DebugDataViewController.swift
//  ITBooksStore
//
//  Created by pkh on 2021/08/03.
//

import UIKit

typealias DebugCallBackClosure = (_ selectIndex: Int, _ value: [String: Any]?) -> Void

class DebugDataViewController: UIViewController, RouterProtocol {
    static var storyboardName: String = "Debug"

    var screenName: String = "DebugDataViewController"

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var treeButton: UIButton!
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var buttonsStack: UIStackView!
    @IBOutlet weak var editButtonView: UIView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchCountLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var steper: UIStepper!
    @IBOutlet weak var searchBackward: UIButton!
    @IBOutlet weak var searchForward: UIButton!
    @IBOutlet weak var bodyView: UIView!
    @IBOutlet weak var bodyViewInScrollview: UIScrollView!
    @IBOutlet weak var indicatoerView: UIActivityIndicatorView!

    private let accessQueue = DispatchQueue(label: "accessQueue_DebugDataViewController", qos: .userInitiated)
    private var dataButtons = [UIButton]()
    @Atomic private var searchItems = [NSRange]()
    private var tempFontSize: CGFloat = 0
    var initialFontSize: CGFloat = CGFloat(DI_UserDefault.showUnitViewData_FontSize) {
        didSet {
            DI_UserDefault.showUnitViewData_FontSize = Int(initialFontSize)
        }
    }
    var searchItemIndex: Int = -1 {
        didSet {
            DispatchQueue.main.async {
                self.searchCountLabel.text = "\(self.searchItemIndex + 1)/\(self.searchItems.count) "
            }
        }
    }
    var debugDatas = [Any]()
    var editCallBack: DebugCallBackClosure?
    var isTreeMode = true {
        didSet {
            setTreeMode(mode: isTreeMode)
        }
    }
    var isEditMode = false {
        didSet {
            editButton.isSelected = isEditMode
            if isEditMode {
                editButtonView.goneHeight = false
                textView.isEditable = true
            }
            else {
                editButtonView.goneHeight = true
                textView.isEditable = false
            }
        }
    }
    var isSearchMode = false {
        didSet {
            searchButton.isSelected = isSearchMode
            if isSearchMode {
                searchItemIndex = -1
                searchItems.removeAll()
                searchView.goneHeight = false
                searchTextField.becomeFirstResponder()
            }
            else {
                let attributedString = NSMutableAttributedString(attributedString: self.textView.attributedText)
                searchItems.forEach { attributedString.removeAttribute(NSAttributedString.Key.backgroundColor, range: $0) }
                searchItems.removeAll()
                textView.attributedText = attributedString
                searchView.goneHeight = true
                searchTextField.resignFirstResponder()
            }
        }
    }
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard debugDatas.count > 0 else { return }

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        isEditMode = false
        isSearchMode = false
        steper.value = Double( initialFontSize )
        textView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 100, right: 0)

        if debugDatas.count > 1 {
            debugDatas.forEach { debugData in
                let className: String
                if let debugData = debugData as? PKHParser {
                    className = debugData.className
                }
                else {
                    className = String(describing: type(of: debugData))
                }

                let btn = UIButton(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
                btn.titleLabel?.font = FontName.APPLE_SD_LIGHT.size(11)
                btn.setTitleColor(.blue, for: .normal)
                btn.setTitle(" \(className) ", for: .normal)
                btn.backgroundColor = .gray
                btn.borderWidth = 1
                btn.borderColor = .black
                btn.addAction(for: .touchUpInside) { [weak self] btn in
                    guard let self = self else { return }
                    self.dataButtons.forEach { $0.isSelected = false }
                    btn.isSelected = true
                    self.setTreeMode(mode: self.isTreeMode, debugData: debugData)
                }
                buttonsStack.addArrangedSubview(btn)
                dataButtons.append(btn)
            }
            dataButtons[safe: 0]?.isSelected = true
            self.setTreeMode(mode: self.isTreeMode, debugData: debugDatas.first)
        }
        else {
            buttonsView.goneHeight = true
            self.setTreeMode(mode: self.isTreeMode, debugData: debugDatas.first)
        }

        textView.addPinchGesture { [weak self] (gestureRecognizer) in
            guard let self = self else { return }
            guard let gestureRecognizer = gestureRecognizer as? UIPinchGestureRecognizer else { return }
            if gestureRecognizer.state == UIPinchGestureRecognizer.State.began {
                // 시작 상태이면 현재 글자 크기를 저장
                self.tempFontSize = self.textView.font?.pointSize ?? self.initialFontSize
            }
            else {
                // 시작 상태가 아니면 텍스트의 글자 크기를 변경
                let size = self.tempFontSize * gestureRecognizer.scale
                self.textView.font = self.textView.font?.withSize(size)

                if gestureRecognizer.state != UIPinchGestureRecognizer.State.changed {
                    self.initialFontSize = size
                    self.steper.value = Double( size )
                    self.setTextSizeChange()
                }
            }
        }

        if editCallBack == nil {
            editButton.isEnabled = false
        }
    }

    @IBAction func onTree(_ sender: UIButton) {
        isTreeMode = !isTreeMode
    }

    @IBAction func onBackButton(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

    func alertErrorMessage(value: String, error: Error) {
        DispatchQueue.main.async {
            alert(title: "Error", message: "\(error)")
            self.textView.attributedText = NSAttributedString(string: value)
        }
    }

    @IBAction func onEditButton(_ sender: UIButton) {
        isEditMode = !isEditMode
    }

    func stringToDic(string: String) -> [String: Any]? {
        if let jsonData: Data = string.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any]
            }
            catch {
                alertErrorMessage(value: string, error: error)
                return nil
            }
        }

        return nil
    }

    func stringToTreeJson(string: String) -> String? {
        do {
            if let dic = stringToDic(string: string) {
                let data = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
                return String(data: data, encoding: .utf8)?.replacingOccurrences(of: "\\/", with: "/")
            }
        }
        catch {
            alertErrorMessage(value: string, error: error)
            return nil
        }

        return nil
    }

    func setTextSizeChange() {
        self.view.layoutIfNeeded()
        self.textView.widthConstraint = max(self.textView.attributedText.size().w, self.bodyView.w) + 50
        //            self.textView.heightConstraint = max(self.textView.attributedText.size().h, self.bodyView.h) + 100
        self.textView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: self.textView.widthConstraint - self.bodyViewInScrollview.w)
    }

    func setTreeMode(mode: Bool, debugData: Any? = nil) {
        var string: String
        if let debugData = debugData {
            if let debugData = debugData as? PKHParser, let stringJson = debugData._debugJsonDic.jsonString() {
                titleLabel.text = debugData.className
                string = stringJson
            }
            else {
                titleLabel.text = String(describing: type(of: debugData))
                string = "\(debugData)"
            }
        }
        else {
            string = textView.attributedText.string
        }

        if mode {
            if let string = self.stringToTreeJson(string: string) {
                textView.bounces = false
                debugStringToAttributedString(string: string) { [weak self] attributedString in
                    guard let self = self else { return }
                    self.textView.attributedText = attributedString
                        self.setTextSizeChange()
                }
            }
        }
        else {
            let string = string.trim().replacingOccurrences(of: "\n", with: "")
            debugStringToAttributedString(string: string) { [weak self] attributedString in
                guard let self = self else { return }
                self.textView.attributedText = attributedString
                self.textView.bounces = true
                self.textView.widthConstraint = self.bodyView.w
//                self.textView.heightConstraint = self.bodyView.h
                self.textView.scrollIndicatorInsets = .zero
            }
        }
    }

    func debugStringToAttributedString(string: String, completed: @escaping (NSMutableAttributedString) -> Void) {
        searchItems.removeAll()
        indicatoerView.isHidden = false
        indicatoerView.startAnimating()

        accessQueue.async {
            let attributedString = NSMutableAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.systemFont(ofSize: self.initialFontSize)])
            let range = NSRange(location: 0, length: string.count)

            let matchings = try? NSRegularExpression(pattern: "\"(.)+\" : (\"(.)*\"|null|true|false|[0-9]+|\\{|\\[)", options: [.caseInsensitive]).matches(in: string, range: range)
            matchings?.forEach {
                let keyMatchings = try? NSRegularExpression(pattern: "\"(.)+\" :", options: .caseInsensitive).matches(in: string, range: $0.range)
                keyMatchings?.forEach { attributedString.addAttribute(.foregroundColor, value: UIColor(hex: 0x666666), range: NSRange(location: $0.range.location + 1, length: $0.range.length - 4)) }

                let valueMatchings = try? NSRegularExpression(pattern: ": \"(.)+\"", options: .caseInsensitive).matches(in: string, range: $0.range)
                valueMatchings?.forEach { attributedString.addAttribute(.foregroundColor, value: UIColor(hex: 0x046407), range: NSRange(location: $0.range.location + 3, length: $0.range.length - 4)) }

                let valueBoolMatchings = try? NSRegularExpression(pattern: "\"(Y|N|TRUE|FALSE)\"", options: .caseInsensitive).matches(in: string, range: $0.range)
                valueBoolMatchings?.forEach { attributedString.addAttribute(.foregroundColor, value: UIColor(hex: 0xe67300), range: NSRange(location: $0.range.location + 1, length: $0.range.length - 2)) }

                let valueBool2Matchings = try? NSRegularExpression(pattern: ": (true|false)", options: .caseInsensitive).matches(in: string, range: $0.range)
                valueBool2Matchings?.forEach { attributedString.addAttribute(.foregroundColor, value: UIColor(hex: 0xe67300), range: NSRange(location: $0.range.location + 2, length: $0.range.length - 2)) }

                let valueIntMatchings = try? NSRegularExpression(pattern: ": ([0-9])+", options: .caseInsensitive).matches(in: string, range: $0.range)
                valueIntMatchings?.forEach { attributedString.addAttribute(.foregroundColor, value: UIColor(hex: 0xd21404), range: NSRange(location: $0.range.location + 2, length: $0.range.length - 2)) }

                let valueNullMatchings = try? NSRegularExpression(pattern: ": (null)", options: .caseInsensitive).matches(in: string, range: $0.range)
                valueNullMatchings?.forEach { attributedString.addAttribute(.foregroundColor, value: UIColor(hex: 0xe75ef5), range: NSRange(location: $0.range.location + 2, length: $0.range.length - 2)) }

                let keyObjMatchings = try? NSRegularExpression(pattern: "\"(.)+\" : \\{", options: [.caseInsensitive]).matches(in: string, range: $0.range)
                keyObjMatchings?.forEach { attributedString.addAttribute(.foregroundColor, value: UIColor(hex: 0x8968CD), range: NSRange(location: $0.range.location + 1, length: $0.range.length - 6) ) }

                let keyArrayMatchings = try? NSRegularExpression(pattern: "\"(.)+\" : \\[", options: [.caseInsensitive]).matches(in: string, range: $0.range)
                keyArrayMatchings?.forEach { attributedString.addAttribute(.foregroundColor, value: UIColor(hex: 0x228aae), range: NSRange(location: $0.range.location + 1, length: $0.range.length - 6) ) }
            }

            DispatchQueue.main.async {
                completed(attributedString)
                self.indicatoerView.stopAnimating()
            }

        }
    }

    @IBAction func onEditOk(_ sender: UIButton) {
        let string = textView.attributedText.string.replacingOccurrences(of: "/", with: "\\/")
//        string = string.replacingOccurrences(of: "\u{201c}", with: "\u{0022}").replacingOccurrences(of: "\u{201d}", with: "\u{0022}")
        print("Set Debug Data \n\(string)")
        if let dic = stringToDic(string: string) {
            if dataButtons.count > 0 {
                var selectIndex = 0
                for (index, item) in dataButtons.enumerated() {
                    if item.isSelected == true {
                        selectIndex = index
                        break
                    }
                }
                self.editCallBack?(selectIndex, dic)
            }
            else {
                self.editCallBack?(0, dic)
            }
            self.navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func onEditCancel(_ sender: UIButton) {
        isEditMode = false
        setTreeMode(mode: isTreeMode)
    }

    @IBAction func onSearchMode(_ sender: UIButton) {
        isSearchMode = !isSearchMode
    }

    private func moveCursorRelativeToBeginning(with offset: Int, rangeLength: Int = 0) {
          guard let startPosition = textView.position(from: textView.beginningOfDocument, offset: offset),
                let endPosition = textView.position(from: startPosition, offset: rangeLength) else { return }
        textView.becomeFirstResponder()
        textView.selectedTextRange = textView.textRange(from: startPosition, to: endPosition)
        let caret = textView.caretRect(for: textView.selectedTextRange!.start)
        let textViewRect = CGRect(x: 0, y: caret.y - 20, width: caret.w + 40, height: caret.h + 40)
        textView.scrollRectToVisible(textViewRect, animated: false)
        let scrollViewRect = CGRect(x: caret.x - 20, y: 0, width: caret.w + 40, height: caret.h + 40)
        bodyViewInScrollview.scrollRectToVisible(scrollViewRect, animated: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001, execute: {
            self.textView.flashScrollIndicators()
        })
      }

    func setSearchIndex(value: Int) {
        searchItemIndex = value
        if searchItemIndex > searchItems.count - 1 {
            searchItemIndex = 0
        }
        if searchItemIndex < 0 {
            searchItemIndex = searchItems.count - 1
        }
    }
    @IBAction func onSearchForward(_ sender: UIButton) {
        setSearchIndex(value: searchItemIndex + 1)
        if let range = searchItems[safe: searchItemIndex] {
            moveCursorRelativeToBeginning(with: range.location, rangeLength: range.length)
        }
    }

    @IBAction func onSearchBackward(_ sender: UIButton) {
        setSearchIndex(value: searchItemIndex - 1)
        if let range = searchItems[safe: searchItemIndex] {
            moveCursorRelativeToBeginning(with: range.location, rangeLength: range.length)
        }
    }

    @IBAction func onSteper(_ sender: UIStepper) {
        let value = CGFloat(steper.value)

        self.textView.font = self.textView.font?.withSize(value)
        initialFontSize = value
        setTextSizeChange()
    }

    @objc func keyboardWillChangeFrame(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
           let animationCurveOption = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            if self.view.h == keyboardFrame.cgRectValue.origin.y {
                UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: UIView.AnimationOptions(rawValue: animationCurveOption), animations: {
                    self.editButtonView.bottomConstraint = 0
                    self.view.layoutIfNeeded()
                })

            }
            else {
                var safeArea: CGFloat
                if #available(iOS 11.0, *) {
                    safeArea = view.safeAreaInsets.bottom
                } else {
                    safeArea = bottomLayoutGuide.length
                }

                UIView.animate(withDuration: TimeInterval(duration), delay: 0.0, options: UIView.AnimationOptions(rawValue: animationCurveOption), animations: {
                    var height = keyboardFrame.cgRectValue.size.height
                    if safeArea > 0 {
                        height -= safeArea
                    }
                    self.editButtonView.bottomConstraint = height
                    self.view.layoutIfNeeded()
                })
            }
        }
    }

    func onSearchKeyword() {
        // "\\u201c" "\\u201d"
        // "”"
//        let string = searchTextField.text?.replacingOccurrences(of: "\u{201c}", with: "\u{0022}").replacingOccurrences(of: "\u{201d}", with: "\u{0022}")
        guard let searchString = searchTextField.text, searchString.isEmpty == false else { return }
        guard let attributedText = self.textView.attributedText else { return }

        indicatoerView.isHidden = false
        indicatoerView.startAnimating()

        accessQueue.async {
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            self.searchItems.forEach { attributedString.removeAttribute(NSAttributedString.Key.backgroundColor, range: $0) }
            self.searchItems.removeAll()
            let range = NSRange(location: 0, length: attributedString.string.count)
            let regex = try? NSRegularExpression( pattern: searchString, options: [.caseInsensitive])
            regex?.enumerateMatches( in: attributedString.string, options: NSRegularExpression.MatchingOptions(), range: range, using: { (textCheckingResult, _, _) -> Void in
                if let subRange = textCheckingResult?.range {
                    attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.yellow, range: subRange)
                    self.searchItems.append(subRange)
                }
            })
            DispatchQueue.main.async {
                self.searchItemIndex = -1
                self.textView.attributedText = attributedString
                if self.searchItems.count > 0 {
                    self.view.layoutIfNeeded()
                    self.onSearchForward(self.searchForward)
                    self.searchBackward.isEnabled = true
                    self.searchForward.isEnabled = true
                }
                else {
                    self.searchBackward.isEnabled = false
                    self.searchForward.isEnabled = false

                }

                self.indicatoerView.stopAnimating()
            }
        }

    }
}

// MARK: - UITextFieldDelegate
extension DebugDataViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onSearchKeyword()
        return true
    }
}

extension DebugDataViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        print("click URL: \(URL)")
        return true
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isTreeMode, scrollView == self.bodyViewInScrollview {
            self.textView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: self.textView.widthConstraint - scrollView.w - scrollView.contentOffset.x)
        }
    }
}
