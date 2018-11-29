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

    private let tableView: UITableView
    private let searchTextField: UITextField
    private let cellReuseIdentifier = "photosCell"
    private let searchActivityIndicatorView = UIActivityIndicatorView()
    private let preheatPhotosSerialQueue = DispatchQueue(label: "preheat.FlickrPhotos")
    
    private var page = 1
    private var pages = 1
    private var photos: [Photo]?
    private var isSearching = false
    
    private lazy var loadingFooterView: UIView = {
        let footerView = UIView()
        footerView.backgroundColor = .white
        let activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.style = .gray
        activityIndicatorView.startAnimating()
        footerView.addSubview(activityIndicatorView)
        activityIndicatorView.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
        })
        return footerView
    }()
    
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
        tableView.prefetchDataSource = self
        tableView.tableFooterView = UIView()
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
    
    private func search(query: String, page: Int) {
        isSearching = true
        flickrPhotosStore.search(query: query, page: page) { (response) in
            self.searchActivityIndicatorView.stopAnimating()
            self.isSearching = false
            self.tableView.tableFooterView = UIView()
            guard case let .success(photoData) = response else {
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
        searchActivityIndicatorView.startAnimating()
        self.photos = []
        search(query: query, page: 1)
        return true
    }
}

extension FlickrPhotosViewController: UITableViewDataSource, UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.photos?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FlickrTableViewCell.reuseIdentifier, for: indexPath) as? FlickrTableViewCell, let photo = self.photos?[indexPath.row] else {
            assertionFailure()
            return UITableViewCell()
        }
        cell.tag = indexPath.row
        cell.activityIndicator.startAnimating()
        flickrPhotosStore.downloadPhoto(photo) { (response) in
            cell.activityIndicator.stopAnimating()
            guard case let .success(image) = response, cell.tag == indexPath.row else {
                return
            }
            cell.photoImageView.image = image
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        self.preheatPhotosSerialQueue.async {
            let photos = indexPaths.compactMap({ self.photos?[$0.row] })
            photos.forEach({ self.flickrPhotosStore.downloadPhoto($0, completionHandler: nil) })
        }
    }
    
    func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        self.preheatPhotosSerialQueue.async {
            guard let urls = self.photos?.compactMap({ $0.url }) else { return }
            self.flickrPhotosStore.cancelPrefetch(urls: urls)
        }
    }
}

extension FlickrPhotosViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let photo = self.photos?[indexPath.row] else { return 0 }
        return photo.size.height
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetY = scrollView.contentOffset.y
        guard contentOffsetY >= (scrollView.contentSize.height - scrollView.bounds.height),
            let query = searchTextField.text,
            page < pages,
            isSearching == false
        else { return }
        //reached the end of the scrollview, and there are still more pages available, so paginate
        tableView.tableFooterView = loadingFooterView
        let nextPage = page + 1
        self.search(query: query, page: nextPage)
    }
}
