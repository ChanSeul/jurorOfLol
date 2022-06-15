//
//  RxUtil.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/04.
//

import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base: UIScrollView {
    func reachedBottom(offset: CGFloat = 100.0) -> ControlEvent<Void> {
        let event = contentOffset.flatMap { [weak base] contentOffset -> Observable<Void> in
            guard let scrollView = base else { return Observable.empty() }
            let visibleHeight = scrollView.frame.height - scrollView.contentInset.top - scrollView.contentInset.bottom
            let position = contentOffset.y + scrollView.contentInset.top
            let threshold = scrollView.contentSize.height - visibleHeight - offset
            return threshold > 0 && position > threshold ? Observable.just(()) : Observable.empty()
        }
        return ControlEvent(events: event)
    }
}
