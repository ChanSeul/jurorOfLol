//
//  UploadViewController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/03/01.
//

import Foundation
import UIKit
import FirebaseFirestore
import KMPlaceholderTextView
import Firebase
import RxSwift
import RxCocoa

enum UploadType: String {
    case new
    case edit
}

class UploadViewController: UIViewController {
    let viewModel: UploadViewModelType?
    let uploadType: UploadType
//    let prepost: ViewPost?
    var disposeBag = DisposeBag()
    
    init(viewModel: UploadViewModelType = UploadViewModel(), uploadType: UploadType, prepost: ViewPost? = nil) {
        self.viewModel = viewModel
        self.uploadType = uploadType
        if prepost != nil {
            var prepost = prepost!
            prepost.url = "https://youtu.be/" + prepost.url
            self.viewModel?.writePost.onNext(prepost)
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("UploadViewController init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        configureUI()
        bind()
    }
    
    //MARK: UI
    
    let uploadTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        tableView.register(UploadCell.self, forCellReuseIdentifier: "uploadcell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        return tableView
    }()
    
    let seperatorView: UIView = {
        let seperatorView = UIView()
        seperatorView.translatesAutoresizingMaskIntoConstraints = false
        seperatorView.backgroundColor = .systemGray4
        return seperatorView
    }()
    
    func configureUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        navigationController?.navigationBar.tintColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "완료", style: .plain, target: self, action: nil)
        navigationController?.navigationBar.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        uploadTableView.delegate = self
        uploadTableView.dataSource = self
        
        let guide = view.safeAreaLayoutGuide
        
        view.addSubview(uploadTableView)
        view.addSubview(seperatorView)
        
        NSLayoutConstraint.activate([
            uploadTableView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            uploadTableView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            uploadTableView.topAnchor.constraint(equalTo: guide.topAnchor),
            uploadTableView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            
            seperatorView.leadingAnchor.constraint(equalTo: uploadTableView.leadingAnchor),
            seperatorView.trailingAnchor.constraint(equalTo: uploadTableView.trailingAnchor),
            seperatorView.topAnchor.constraint(equalTo: uploadTableView.topAnchor),
            seperatorView.heightAnchor.constraint(equalToConstant: 0.25)
        ])
        
    }
    func bind() {
        guard let viewModel = self.viewModel else { return }
        navigationItem.rightBarButtonItem?.rx.tap
            .withLatestFrom(viewModel.writtenPost)
            .subscribe(onNext: { [weak self] written in
                guard let self = self else { return }
                if written.url.youTubeId == nil { self.showAlert("유효하지 않은 유튜브 URL입니다.", ""); return }
                else if written.champion1 == "" { self.showAlert("본인의 주장을 입력하세요.", ""); return }
                else if written.champion2 == "" { self.showAlert("상대방의 주장을 입력하세요.", ""); return }
                else if written.text == "" { self.showAlert("본문을 작성해주세요.", ""); return }
                
                switch self.uploadType {
                case .new:
                    self.viewModel?.uploadPost.onNext(())
                case .edit:
                    self.viewModel?.writtenPost
                        .take(1)
                        .subscribe(onNext: { writtenPost in
                            self.viewModel?.editPost.onNext(writtenPost.docId)
                        })
                        .disposed(by: self.disposeBag)
                }
                self.dismiss(animated: true, completion: nil)
                Singleton.shared.refreshHomeTableView.accept(true)
                
            })
            .disposed(by: disposeBag)
        
        navigationItem.leftBarButtonItem?.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }

}

extension UploadViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let uploadcell = tableView.dequeueReusableCell(withIdentifier: "uploadcell", for: indexPath) as! UploadCell
        uploadcell.selectionStyle = .none
        uploadcell.textView.tag = indexPath.row
        //uploadcell.textView.delegate = self
        guard let viewModel = self.viewModel else { return uploadcell }
        
        switch uploadcell.textView.tag {
        case 0:
            uploadcell.textView.placeholder = "유튜브 URL('일부 공개'로 업로드시, 유튜브에 노출되지 않습니다.)"
            uploadcell.textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
            uploadcell.textView.rx.didChange
                .withLatestFrom(viewModel.writtenPost)
                .subscribe(onNext: { (written) in
                    var newWritten = written
                    newWritten.url = uploadcell.textView.text
                    viewModel.writePost.onNext(newWritten)
                })
                .disposed(by: disposeBag)
            if uploadType == .edit {
                viewModel.writtenPost
                    .take(1)
                    .subscribe(onNext: { writtenPost in
                        uploadcell.textView.text = writtenPost.url
                    })
                    .disposed(by: uploadcell.disposeBag)
            }
        case 1:
            uploadcell.textView.placeholder = "본인의 주장."
            uploadcell.textView.rx.didChange
                .withLatestFrom(viewModel.writtenPost)
                .subscribe(onNext: { (written) in
                    var newWritten = written
                    newWritten.champion1 = uploadcell.textView.text
                    viewModel.writePost.onNext(newWritten)
                })
                .disposed(by: disposeBag)
            if uploadType == .edit {
                viewModel.writtenPost
                    .take(1)
                    .subscribe(onNext: { writtenPost in
                        uploadcell.textView.text = writtenPost.champion1
                    })
                    .disposed(by: uploadcell.disposeBag)
            }
        case 2:
            uploadcell.textView.placeholder = "상대방의 주장."
            uploadcell.textView.rx.didChange
                .withLatestFrom(viewModel.writtenPost)
                .subscribe(onNext: { (written) in
                    var newWritten = written
                    newWritten.champion2 = uploadcell.textView.text
                    viewModel.writePost.onNext(newWritten)
                })
                .disposed(by: disposeBag)
            if uploadType == .edit {
                viewModel.writtenPost
                    .take(1)
                    .subscribe(onNext: { writtenPost in
                        uploadcell.textView.text = writtenPost.champion2
                    })
                    .disposed(by: uploadcell.disposeBag)
            }
        case 3:
            uploadcell.textView.placeholder = "당시 상황에 대해 자세히 적어주세요."
            uploadcell.blankView.heightAnchor.constraint(equalToConstant: view.frame.height * 0.6).isActive = true
            
            uploadcell.textView.rx.didChange
                .withLatestFrom(viewModel.writtenPost)
                .subscribe(onNext: { [weak self] written in
                    guard let self = self else { return }
                    var newWritten = written
                    newWritten.text = uploadcell.textView.text
                    viewModel.writePost.onNext(newWritten)
                    
                    let size = uploadcell.textView.bounds.size
//                    let newHeight = self.requiredHeight(for: uploadcell.textView.text, width: size.width, font: uploadcell.textView.font)
                    let newSize = uploadcell.textView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
                    if size.height < newSize.height + 0.5 { //왜 0.5차이가 나는지 모름.
                        let offset = newSize.height - size.height
                        let currentOffset = self.uploadTableView.contentOffset
                        UIView.performWithoutAnimation {
                            self.uploadTableView.contentOffset = CGPoint(x: currentOffset.x, y: currentOffset.y + offset)
                        }
                        
                    }
                })
                .disposed(by: disposeBag)
            
            uploadcell.textView.rx.didBeginEditing
                .subscribe(onNext: {
                    self.uploadTableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: false)
                })
                .disposed(by: disposeBag)
                    
            if uploadType == .edit {
                viewModel.writtenPost
                    .take(1)
                    .subscribe(onNext: { writtenPost in
                        uploadcell.textView.text = writtenPost.text
                    })
                    .disposed(by: uploadcell.disposeBag)
            }
        default:
            break
        }
        
        uploadcell.textView.rx.didChange
            .asDriver()
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                let size = self.uploadTableView.bounds.size
                let newSize = self.uploadTableView.sizeThatFits(CGSize(width: size.width,
                                                            height: CGFloat.greatestFiniteMagnitude))
                if size.height != newSize.height {
                    UIView.setAnimationsEnabled(false)
                    self.uploadTableView.beginUpdates()
                    self.uploadTableView.endUpdates()
                    UIView.setAnimationsEnabled(true)
                }
            })
            .disposed(by: disposeBag)
        
        return uploadcell
    }
}

