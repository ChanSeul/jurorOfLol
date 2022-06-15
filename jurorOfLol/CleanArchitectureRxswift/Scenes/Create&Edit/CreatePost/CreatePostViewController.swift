//
//  CreatePostViewController.swift
//  jurorOfLol
//
//  Created by 찬슬조 on 2022/06/02.
//

import Foundation
import UIKit
import RxSwift

final class CreatePostViewController: UIViewController, UploadView {
    var viewModel: CreatePostViewModel!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        configureUI()
        connect()
    }
    
    //MARK: UI
    
    let uploadTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        tableView.register(UploadCell.self, forCellReuseIdentifier: UploadCell.identifier)
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
}
