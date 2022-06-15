//
//  UploadView.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/15.
//

import UIKit
import RxSwift

protocol UploadView {
    var uploadTableView: UITableView { get }
    var disposeBag: DisposeBag { get }
}

extension UploadView {
    func ChangeContentOffset(cell: UploadCell, indexPath: IndexPath, text: String) {
        let preSize = cell.textView.bounds.size
        let newSize = cell.textView.sizeThatFits(CGSize(width: preSize.width, height: CGFloat.greatestFiniteMagnitude))

        if preSize.height < newSize.height + 0.5 {
            let offset = newSize.height - preSize.height
            let currentOffset = self.uploadTableView.contentOffset
            UIView.performWithoutAnimation {
                self.uploadTableView.contentOffset = CGPoint(x: currentOffset.x, y: currentOffset.y + offset)
            }
        }
    }
    
    func ResizeTableView() {
        let preSize = uploadTableView.bounds.size
        let newSize = uploadTableView.sizeThatFits(CGSize(width: preSize.width,
                                                    height: CGFloat.greatestFiniteMagnitude))
        if preSize.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            uploadTableView.beginUpdates()
            uploadTableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        }
    }
}
