//
//  Utils.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import UIKit
import Firebase
//func heightWithConstrainedWidth(text: String, width: CGFloat, font: UIFont) -> CGFloat {
//    let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
//    let boundingBox = text.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
//    return boundingBox.height
//}
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
    
}

extension UIButton {
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let margin: CGFloat = 20
        let hitArea = self.bounds.insetBy(dx: -margin, dy: -margin)
        return hitArea.contains(point)
      }
}

