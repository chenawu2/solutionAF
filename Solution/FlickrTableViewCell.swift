//
//  FlickrTableViewCell.swift
//  Solution
//
//  Created by Chen Wu on 11/28/18.
//  Copyright © 2018 Chen Wu. All rights reserved.
//

import Foundation
import UIKit

final class FlickrTableViewCell: UITableViewCell {
    let photoImageView = UIImageView()
    let activityIndicator = UIActivityIndicatorView()
    
    static let reuseIdentifier = "flickerTableViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        activityIndicator.style = .gray
        activityIndicator.startAnimating()
        contentView.addSubview(activityIndicator)
        contentView.addSubview(photoImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        activityIndicator.startAnimating()
        photoImageView.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        activityIndicator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        photoImageView.snp.makeConstraints { (make) in
            make.top.left.bottom.right.equalToSuperview()
        }
    }
}
