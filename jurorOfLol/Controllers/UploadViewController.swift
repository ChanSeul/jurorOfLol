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
    let prepost: ViewPost?
    var delegate: RefreshDelegate?
    var disposeBag = DisposeBag()
    
    init(viewModel: UploadViewModelType = UploadViewModel(), uploadType: UploadType, prepost: ViewPost? = nil) {
        self.viewModel = viewModel
        self.uploadType = uploadType
        self.prepost = prepost
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("UploadViewController init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        configureUI()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if uploadType == .edit {
            if let urlCell = uploadTableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? UploadCell,
               let champion1Cell = uploadTableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? UploadCell,
               let champion2Cell = uploadTableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? UploadCell,
               let mainTextCell = uploadTableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? UploadCell,
               let prepost = self.prepost {
                urlCell.textView.text = "https://youtu.be/" + prepost.url
                champion1Cell.textView.text = prepost.champion1
                champion2Cell.textView.text = prepost.champion2
                mainTextCell.textView.text = prepost.text
                viewModel?.writePost.onNext(prepost.ViewPostIntoUploadingPost(viewPost: prepost))
            }
        }
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
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "완료", style: .plain, target: self, action: nil)
        navigationController?.navigationBar.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
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
                if written.url.youTubeId == nil { self?.showAlert("유효하지 않은 유튜브 URL입니다.", ""); return }
                else if written.champion1 == "" { self?.showAlert("작성자의 챔피언을 입력하세요.", ""); return }
                else if written.champion2 == "" { self?.showAlert("상대방의 챔피언을 입력하세요.", ""); return }
                else if written.text == "" { self?.showAlert("본문을 작성해주세요.", ""); return }
                
                switch self?.uploadType {
                case .new:
                    self?.viewModel?.uploadPost.onNext(())
                case .edit:
                    if let prepost = self?.prepost {
                        self?.viewModel?.editPost.onNext((prepost.docId))
                    }
                case .none:
                    return
                }
                
                self?.dismiss(animated: true, completion: nil)
                self?.delegate?.refresh()
                
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
        case 1:
            uploadcell.textView.placeholder = "작성자 챔피언."
            uploadcell.textView.rx.didChange
                .withLatestFrom(viewModel.writtenPost)
                .subscribe(onNext: { (written) in
                    var newWritten = written
                    newWritten.champion1 = uploadcell.textView.text
                    viewModel.writePost.onNext(newWritten)
                })
                .disposed(by: disposeBag)
        case 2:
            uploadcell.textView.placeholder = "상대방 챔피언."
            uploadcell.textView.rx.didChange
                .withLatestFrom(viewModel.writtenPost)
                .subscribe(onNext: { (written) in
                    var newWritten = written
                    newWritten.champion2 = uploadcell.textView.text
                    viewModel.writePost.onNext(newWritten)
                })
                .disposed(by: disposeBag)
        case 3:
            uploadcell.textView.placeholder = "당시 상황에 대해 자세히 적어주세요."
            uploadcell.blankView.heightAnchor.constraint(equalToConstant: view.frame.height * 0.6).isActive = true
            uploadcell.textView.rx.didChange
                .withLatestFrom(viewModel.writtenPost)
                .subscribe(onNext: { (written) in
                    var newWritten = written
                    newWritten.text = uploadcell.textView.text
                    viewModel.writePost.onNext(newWritten)
                })
                .disposed(by: disposeBag)
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


