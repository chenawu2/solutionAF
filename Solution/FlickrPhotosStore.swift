//
//  FlickrPhotosStore.swift
//  Solution
//
//  Created by Chen Wu on 11/28/18.
//  Copyright © 2018 Chen Wu. All rights reserved.
//

import Foundation
import UIKit

final class FlickrPhotosStore: NSObject {
    
    enum SearchBackendResponse {
        case success (photosData: PhotosMetaDetails)
        case failure (error: Error?)
    }
    
    enum PhotoBackendResponse {
        case success (photo: UIImage)
        case failure (error: Error?)
    }

    let imageCache = NSCache<NSString, UIImage>()
    
    func search(query: String, page: Int, completionHandler: @escaping ((SearchBackendResponse) -> Void)) {
        let urlTemplate = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=675894853ae8ec6c242fa4c077bcf4a0&text=\(query)&extras=url_s&format=json&nojsoncallback=1&per_page=20&page=\(page)"
        guard let url = URL(string: urlTemplate) else {
            completionHandler(.failure(error: nil))
            return
        }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completionHandler(.failure(error: error))
                return
            }
            let dto = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            self.didSearch(dto: dto as? [String : Any], completionHandler: completionHandler)
        }.resume()
    }
    
    private func didSearch(dto: [String : Any]?, completionHandler: @escaping ((SearchBackendResponse) -> Void)) {
        guard let photosDto = dto?["photos"] as? [String : Any]
            else {
                dispatchToMainThread {
                    completionHandler(.failure(error: nil))
                }
                return
        }
        
        let metaData = PhotosMetaDetails(photosDto: photosDto)
        dispatchToMainThread {
            completionHandler(.success(photosData: metaData))
        }
    }
    
    func downloadPhoto(_ photo: Photo, completionHandler: ((PhotoBackendResponse) -> Void)?) {
        if let cachedImage = imageCache.object(forKey: photo.url as NSString) {
            dispatchToMainThread {
                completionHandler?(.success(photo: cachedImage))
            }
            return
        }
        
        guard let url = URL(string: photo.url) else {
            dispatchToMainThread {
                completionHandler?(.failure(error: nil))
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else {
                completionHandler?(.failure(error: error))
                return
            }
            self.imageCache.setObject(image, forKey: photo.url as NSString)
            dispatchToMainThread {
                completionHandler?(.success(photo: image))
            }
        }.resume()
    }
    
    func cancelPrefetch(urls: [String]) {
        let urls = urls.compactMap({ URL(string: $0) })
        URLSession.shared.getTasksWithCompletionHandler { (tasks, _, _) in
            let filteredTasks = tasks.filter({ (task) -> Bool in
                guard let url = task.currentRequest?.url else { return false }
                return urls.contains(url)
            })
            filteredTasks.forEach({ $0.cancel() })
        }
    }
}

struct PhotosMetaDetails {
    let page: Int
    let pages: Int
    let photos: [Photo]
    
    init(photosDto: [String: Any]) {
        let page = photosDto["page"] as? Int ?? 0
        self.page = page
        
        let pages = photosDto["pages"] as? Int ?? 0
        self.pages = pages
        
        let photoDto = photosDto["photo"] as? [[String : Any]]
        self.photos = photoDto?.compactMap({ Photo(photoDto: $0) }) ?? []
    }
}

struct Photo {
    let url: String
    let size: CGSize
    
    init?(photoDto: [String: Any]) {
        guard let url = photoDto["url_s"] as? String,
            let width = Double(photoDto["width_s"] as? String ?? ""),
            let height = Double(photoDto["height_s"] as? String ?? "")
            else { return nil }
        self.url = url
        self.size = CGSize(width: width, height: height)
    }
}

func dispatchToMainThread(_ handler: @escaping () -> Void) {
    DispatchQueue.main.async { handler() }
}
