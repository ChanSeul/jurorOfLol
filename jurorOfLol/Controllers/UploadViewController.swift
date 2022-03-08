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


class UploadViewController: UIViewController {
    let database = Firestore.firestore()
    private var uploadData = post()
    
    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "완료", style: .plain, target: self, action: #selector(complete))
        navigationController?.navigationBar.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        uploadTableView.delegate = self
        uploadTableView.dataSource = self
        configureUI()
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
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    @objc private func complete() {
        guard let url = uploadData.url?.youTubeId else { return showAlert("유효하지 않은 유튜브 URL입니다.", "") }
        guard let champion1 = uploadData.champion1 else { return showAlert("작성자의 챔피언을 입력하세요.", "") }
        guard let champion2 = uploadData.champion2 else { return showAlert("상대방의 챔피언을 입력하세요.", "") }
        guard let text = uploadData.text else { return showAlert("본문을 작성해주세요.", "") }
        guard let user = Auth.auth().currentUser else { return }
        
        database.collection("posts").addDocument(data: ["userID": user.uid,
                                                        "url": url,
                                                        "champion1": champion1,
                                                        "champion1Votes": 0,
                                                        "champion1VotesUsers": [],
                                                        "champion2": champion2,
                                                        "champion2Votes": 0,
                                                        "champion2VotesUsers": [],
                                                        "text": text,
                                                        "date": Date().timeIntervalSince1970])
        
        
        dismiss(animated: true, completion: nil)
    }
}

extension UploadViewController : UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let uploadcell = tableView.dequeueReusableCell(withIdentifier: "uploadcell", for: indexPath) as! UploadCell
        uploadcell.selectionStyle = .none
        uploadcell.textView.tag = indexPath.row
        uploadcell.textView.delegate = self
        
        switch uploadcell.textView.tag {
        case 0:
            uploadcell.textView.placeholder = "유튜브 URL('일부 공개'로 업로드시, 유튜브에 노출되지 않습니다.)"
            uploadcell.textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        case 1:
            uploadcell.textView.placeholder = "작성자 챔피언."
        case 2:
            uploadcell.textView.placeholder = "상대방 챔피언."
        case 3:
            uploadcell.textView.placeholder = "당시 상황에 대해 자세히 적어주세요."
            uploadcell.blankView.heightAnchor.constraint(equalToConstant: view.frame.height * 0.6).isActive = true
        default:
            break
        }
        return uploadcell
    }
    
    func textViewDidChange(_ textView: UITextView) {
        switch textView.tag {
        case 0:
            uploadData.url = textView.text
        case 1:
            uploadData.champion1 = textView.text
        case 2:
            uploadData.champion2 = textView.text
        case 3:
            uploadData.text = textView.text
        default:
            break
        }

        let size = uploadTableView.bounds.size
        let newSize = uploadTableView.sizeThatFits(CGSize(width: size.width,
                                                    height: CGFloat.greatestFiniteMagnitude))
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            uploadTableView.beginUpdates()
            uploadTableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        }
       
    }
}


