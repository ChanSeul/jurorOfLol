//
//  Utils.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import UIKit
import Firebase
import TTTAttributedLabel

extension String {
    var youTubeId: String? {
        let typePattern = "(?:(?:\\.be\\/|embed\\/|v\\/|\\?v=|\\&v=|\\/videos\\/)|(?:[\\w+]+#\\w\\/\\w(?:\\/[\\w]+)?\\/\\w\\/))([\\w-_]+)"
        let regex = try? NSRegularExpression(pattern: typePattern, options: .caseInsensitive)
    
        return regex
            .flatMap { $0.firstMatch(in: self, range: NSMakeRange(0, self.count)) }
            .flatMap { Range($0.range(at: 1), in: self) }
            .map { String(self[$0]) }
    }
}

extension UIViewController {
    func showAlert(_ title: String, _ message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "확인", style: .default))
        present(alertVC, animated: true, completion: nil)
    }
//    public func requiredHeight(for text: String, width: CGFloat, font: UIFont) -> CGFloat {
//        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
//        label.numberOfLines = 0
//        label.font = font
//        label.text = text
//        label.sizeToFit()
//        return label.frame.height
//      }
}

//extension UIButton {
//    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        let margin: CGFloat = 20
//        let hitArea = self.bounds.insetBy(dx: -margin, dy: -margin)
//        return hitArea.contains(point)
//      }
//}

public enum TrailingContent {
    case readmore
    case readless

    var text: String {
        switch self {
        case .readmore: return "...자세히 보기"
        case .readless: return " 간략히"
        }
    }
}

extension UILabel {

    private var minimumLines: Int { return 2 }
    private var highlightColor: UIColor { return .lightGray }

    private var attributes: [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        return [.font: self.font ?? .systemFont(ofSize: 15), .paragraphStyle: paragraphStyle]
    }
    
    public func requiredHeight(for text: String) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: bounds.width, height: CGFloat.greatestFiniteMagnitude))
//        label.numberOfLines = minimumLines
//        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.numberOfLines = 0
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.height
      }

    func highlight(_ text: String, color: UIColor) {
        guard let labelText = self.text else { return }
        let range = (labelText as NSString).range(of: text)

        let mutableAttributedString = NSMutableAttributedString.init(string: labelText)
        mutableAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        self.attributedText = mutableAttributedString
    }

    func appendReadmore(after text: String, trailingContent: TrailingContent) {
        let attrString = NSMutableAttributedString.init(string: text)
        attrString.addAttributes(attributes, range: NSMakeRange(0, attrString.length))
        self.attributedText = attrString
        
        self.numberOfLines = minimumLines
        var minimumLineText = ""
        for _ in 0..<self.minimumLines {
            minimumLineText += "\n"
        }
        let minimumlineHeight = requiredHeight(for: minimumLineText)
        let sentenceText = NSString(string: text)
        let sentenceRange = NSRange(location: 0, length: sentenceText.length)
        var truncatedSentence: NSString = sentenceText
        var endIndex: Int = sentenceRange.upperBound
        let size: CGSize = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
        while truncatedSentence.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size.height > minimumlineHeight {
            if endIndex == 0 {
                break
            }
            endIndex -= 1

            truncatedSentence = NSString(string: sentenceText.substring(with: NSRange(location: 0, length: endIndex)))
            truncatedSentence = (String(truncatedSentence) + trailingContent.text) as NSString

        }
        
        self.text = truncatedSentence as String
        self.highlight(trailingContent.text, color: highlightColor)

    }

    func appendReadLess(after text: String, trailingContent: TrailingContent) {
        self.numberOfLines = 0
        self.text = text
//        if requiredHeight(for: text) > requiredHeight(for: "\n") {
//            self.text = text + trailingContent.text
//            self.highlight(trailingContent.text, color: highlightColor)
//        }
//        else {
//            self.text = text
//        }
    }
}

extension UINavigationItem {
    func setTitleView(title: String) {
        let titleLabel = UILabel()
        let attr: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white, .font: UIFont.boldSystemFont(ofSize: 20)]
        let attrStr = NSMutableAttributedString(string: title, attributes: attr)
        titleLabel.attributedText = attrStr
        titleLabel.sizeToFit()
        self.titleView = titleLabel
    }
}

extension Double {
    func toDateFormat() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: self))
    }
}
