//
//  PostTableCellDelegate.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/03.
//

import Foundation
import RxCocoa

protocol PostTableCellDelegate: AnyObject {
    func showAlert(_ userId: String) -> Driver<Int>
}
