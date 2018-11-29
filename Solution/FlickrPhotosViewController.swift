//
//  FlickrPhotosViewController.swift
//  Solution
//
//  Created by Chen Wu on 11/28/18.
//  Copyright © 2018 Chen Wu. All rights reserved.
//

import UIKit
import SnapKit

final class FlickrPhotosViewController: UIViewController {
    let flickrPhotosStore: FlickrPhotosStore
    
    private var page = 1
    private var pages = 1
    private var photos: [Photo]?
    
    private let tableView: UITableView
    private let searchTextField: UITextField
    private let cellReuseIdentifier = "photosCell"
    private let searchActivityIndicatorView = UIActivityIndicatorView()
    
    init(flickrPhotosStore: FlickrPhotosStore) {
        self.flickrPhotosStore = flickrPhotosStore
        tableView = UITableView()
        searchTextField = UITextField()
        super.init(nibName: nil, bundle: nil)
        
        searchTextField.placeholder = "Search Flickr"
        searchTextField.backgroundColor = .gray
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        view.addSubview(searchTextField)
        searchTextField.snp.makeConstraints { (make) in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(50)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FlickrTableViewCell.self, forCellReuseIdentifier: FlickrTableViewCell.reuseIdentifier)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(searchTextField.snp.bottom)
            make.left.bottom.right.equalTo(view.safeAreaLayoutGuide)
        }
        
        searchActivityIndicatorView.hidesWhenStopped = true
        searchActivityIndicatorView.style = .gray
        searchActivityIndicatorView.stopAnimating()
        view.addSubview(searchActivityIndicatorView)
        searchActivityIndicatorView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    private func search(query: String) {
        searchActivityIndicatorView.startAnimating()
        flickrPhotosStore.search(query: query, page: 1) { (response) in
            self.searchActivityIndicatorView.stopAnimating()
            guard case let .success(photoData) = response else {
                print("error")
                return
            }
            
            let allPhotos = (self.photos ?? []) + photoData.photos
            self.photos = allPhotos
            self.page = photoData.page
            self.pages = photoData.pages
            
            self.tableView.reloadData()
        }
    }
}

extension FlickrPhotosViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard let query = textField.text else { return true }
        search(query: query)
        return true
    }
}

extension FlickrPhotosViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.photos?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FlickrTableViewCell.reuseIdentifier, for: indexPath) as? FlickrTableViewCell, let photo = self.photos?[indexPath.row] else {
            assertionFailure()
            return UITableViewCell()
        }
        cell.tag = indexPath.row
        flickrPhotosStore.downloadPhoto(photo) { (response) in
            guard case let .success(image) = response, cell.tag == indexPath.row else {
                return
            }
            cell.photoImageView.image = image
            cell.photoImageView.sizeToFit()
        }
        return cell
    }
}

extension FlickrPhotosViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let photo = self.photos?[indexPath.row] else { return 0 }
        return photo.size.height
    }
}
