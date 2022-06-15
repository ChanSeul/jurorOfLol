//
//  EditConnection.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/15.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import RxDataSources

extension EditPostViewController {
    func connect() {
        assert(viewModel != nil)
        
        let cancel = navigationItem.leftBarButtonItem!.rx.tap.asObservable()
        let save = navigationItem.rightBarButtonItem!.rx.tap.asObservable()
        let url = BehaviorRelay<String>(value: "")
        let champion1 = BehaviorRelay<String>(value: "")
        let champion2 = BehaviorRelay<String>(value: "")
        let detail = BehaviorRelay<String>(value: "")
        
        let input = EditPostViewModel.Input(cancelTrigger: cancel, saveTrigger: save, url: url.asObservable().skip(1), champion1: champion1.asObservable().skip(1), champion2: champion2.asObservable().skip(1), detail: detail.asObservable().skip(1))
        let output = viewModel.transform(input: input)
        
        output.dismiss.asDriverOnErrorJustComplete()
            .drive()
            .disposed(by: disposeBag)
        output.saveEnabled.asDriverOnErrorJustComplete()
            .drive(navigationItem.rightBarButtonItem!.rx.isEnabled)
            .disposed(by: disposeBag)
        output.edit.asDriverOnErrorJustComplete()
            .drive()
            .disposed(by: disposeBag)
        
        let dataSource =
        RxTableViewSectionedAnimatedDataSource<CreatePostSection>(
            configureCell: { [unowned self] dataSource, tableView, indexPath, inputType in
                let cell = tableView.dequeueReusableCell(withIdentifier: UploadCell.identifier, for: indexPath) as! UploadCell
                let cellEvent = cell.connect(inputType: inputType, viewHeight: view.frame.height)
                
                switch inputType {
                case "url":
                    output.prePost.asDriverOnErrorJustComplete()
                        .map { $0.url }
                        .drive(cell.textView.rx.text)
                        .disposed(by: cell.disposeBag)
                    cellEvent.textChange
                        .do(onNext: { _ in self.ResizeTableView() })
                        .drive(url)
                        .disposed(by: cell.disposeBag)
                case "champion1":
                    output.prePost.asDriverOnErrorJustComplete()
                        .map { $0.champion1 }
                        .drive(cell.textView.rx.text)
                        .disposed(by: cell.disposeBag)
                    cellEvent.textChange
                        .do(onNext: { _ in self.ResizeTableView() })
                        .drive(champion1)
                        .disposed(by: cell.disposeBag)
                case "champion2":
                    output.prePost.asDriverOnErrorJustComplete()
                        .map { $0.champion2 }
                        .drive(cell.textView.rx.text)
                        .disposed(by: cell.disposeBag)
                    cellEvent.textChange
                        .do(onNext: { _ in self.ResizeTableView() })
                        .drive(champion2)
                        .disposed(by: cell.disposeBag)
                case "detail":
                    output.prePost.asDriverOnErrorJustComplete()
                        .map { $0.text }
                        .drive(cell.textView.rx.text)
                        .disposed(by: cell.disposeBag)
                    cellEvent.textChange
                        .drive(detail)
                        .disposed(by: cell.disposeBag)
                    cellEvent.textChange.skip(1)
                        .drive(onNext: {
                            self.ChangeContentOffset(cell: cell, indexPath: indexPath, text: $0)
                            self.ResizeTableView()
                        })
                        .disposed(by: cell.disposeBag)
                default:
                    break
                }
                        
                cellEvent.textEditBegin
                    .drive(onNext: {
                        self.uploadTableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: false)
                    })
                    .disposed(by: cell.disposeBag)
                
                return cell
            },
            canEditRowAtIndexPath: { _, _ in true }
        )
        
        uploadTableView.delegate = nil
        uploadTableView.dataSource = nil
        
        viewModel.EditPostSections().asDriverOnErrorJustComplete()
            .drive(uploadTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
}
