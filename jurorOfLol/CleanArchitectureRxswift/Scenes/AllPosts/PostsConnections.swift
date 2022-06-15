//
//  PostsConnections.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/05/28.
//

import RxCocoa
import RxDataSources
import RxSwift
import UIKit

extension PostsViewController {
    func connect() {
        assert(viewModel != nil)
        
        let viewWillAppear = rx.viewWillAppear
            .take(1)
            .mapToVoid()
            .catchErrorJustComplete()
        let pull = timeLineTableView.refreshControl!.rx
            .controlEvent(.valueChanged)
            .asObservable()
        // 로그인 상태 관찰
        let loginStateChange = UserDefaults.standard.rx.observe(Bool.self, "isLoggedIn").compactMap { $0 }.mapToVoid().skip(1)
        // 게시물 업로드 또는 수정완료 이벤트 관찰
        let uploadCompleted = NotificationCenter.default.rx.notification(.postUploadCompleted).mapToVoid()
        // Pagination을 위해 관찰
        let reachedBottom = timeLineTableView.rx.reachedBottom().asObservable()
        // 우측하단 업로드 버튼 이벤트 관찰
        let uploadTrigger = uploadButton.rx.tap.asObservable()
        // 네비게이션바의 우측 버튼의 액션시트 이벤트 관찰
        let orderTrigger = navigationItem.rightBarButtonItem!.customView!.rx.tapGesture().when(.ended).asObservable().mapToVoid()
            .flatMap {
                self.showAlert(title: nil, message: nil, style: .actionSheet, actions: [AlertAction(title: "취소", style: .cancel), AlertAction(title: "시간순", style: .default), AlertAction(title: "투표순", style: .default)])
            }

        // 아래 3개의 이벤트는 테이블뷰의 cell로부터 오는 이벤트
        // 각 cell의 pollTapped 이벤트를 NotificationCenter를 통해 global하게 받는 이유: 2개 이상의 PostsViewController(ex. 홈화면과 내 동영상) 투표 데이터를 동기화하기위해
        let updateVote = NotificationCenter.default.rx.notification(.pollTapped)
            .map { $0.object as! (PostItemViewModel.ID, Int) }
        let delete = PublishSubject<PostItemViewModel.ID>()
        let edit = PublishSubject<PostItemViewModel.ID>()
        
        let input = PostsViewModel.Input(fetchInitial: Observable.merge(viewWillAppear, pull, loginStateChange, uploadCompleted),
                                         fetchNext: reachedBottom,
                                         orderTrigger: orderTrigger,
                                         updateVote: updateVote,
                                         uploadTrigger: uploadTrigger,
                                         delete: delete,
                                         edit: edit)
        let output = viewModel.transform(input: input)
        
        let dataSource =
        RxTableViewSectionedAnimatedDataSource<PostItemViewModelSection>(
            configureCell: { [unowned self] dataSource, tableView, indexPath, id in
                let cell = tableView.dequeueReusableCell(withIdentifier: PostTableViewCell.identifier, for: indexPath) as! PostTableViewCell

                // 셀 우측 상단의 수정&삭제 액션시트를 띄우기 위해 delegate지정
                cell.delegate = self

                // 셀 바인딩후, 다수의 셀 이벤트 값 관찰
                let cellEvent = cell.connect(postItem: output.posts.asDriverOnErrorJustComplete().compactMap { $0.first(where: { $0.id == id }) },
                                             voteData: output.voteData.asDriverOnErrorJustComplete())

                // 본문 텍스트 누르면 간략히 보거나 전체 텍스트 보기
                cellEvent.detailTapped
                    .drive(onNext: { [unowned cell] detail in
                        cell.appendMoreOrLess(detail: detail)
                        UIView.performWithoutAnimation {
                            self.timeLineTableView.performBatchUpdates(nil)
                        }
                    })
                    .disposed(by: cell.disposeBag)
                // 우측상단 버튼의 액션시트 ( 1번 = 수정, 2번 = 삭제)
                cellEvent.editBtnTapped
                    .filter { $0.1 == 1 }
                    .map { $0.0 }
                    .drive(edit)
                    .disposed(by: cell.disposeBag)

                cellEvent.editBtnTapped
                    .filter { $0.1 == 2 }
                    .map { $0.0 }
                    .drive(delete)
                    .disposed(by: cell.disposeBag)

                return cell
            },
            canEditRowAtIndexPath: { _, _ in true }
        )

        timeLineTableView.dataSource = nil
        timeLineTableView.delegate = nil

        viewModel.PostItemViewModelSections(postItem: output.posts)
            .asDriverOnErrorJustComplete()
            .drive(timeLineTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        output.fetching
            .asDriverOnErrorJustComplete()
            .drive(timeLineTableView.refreshControl!.rx.isRefreshing)
            .disposed(by: disposeBag)
        // 내 동영상 보기에서는 우측 하단의 업로드 버튼과 내비게이션 바의 우측 버튼이 보이지 않음.
        output.uploadBtnHidden
            .asDriverOnErrorJustComplete()
            .drive(uploadButton.rx.isHidden, navigationItem.rightBarButtonItem!.customView!.rx.isHidden)
            .disposed(by: disposeBag)
        
        output.error
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [unowned self] _ in
                //self.showAlert("Error", $0.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
}
