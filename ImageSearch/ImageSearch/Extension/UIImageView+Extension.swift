//
//  UIImageView+Extension.swift
//  ImageSearch
//
//  Created by Dabeeo on 2021/07/30.
//

import Foundation
import UIKit
import Kingfisher

extension UIImageView {
    //url로 부터 이미지 가져오기(캐시처리 포함)
    func setThumbImage(with urlString: String) {
        let cache = ImageCache.default
        cache.retrieveImage(forKey: urlString, options: nil) { result in // 캐시에서 키를 통해 이미지를 가져온다.
            switch result {
            case .success(let value):
                if let image = value.image {
                    // 캐시 이미지
                    self.image = image
                } else {
                    guard let url = URL(string: urlString) else { return }
                    let resource = ImageResource(downloadURL: url, cacheKey: urlString) // URL로부터 이미지를 다운받고 String 타입의 URL을 캐시키로 지정하고
                    
                    //이미지 resizing
                    let screenWidth = UIScreen.main.bounds.width
                    let cellMargin: CGFloat = 20.0
                    let cellSpace: CGFloat = 10.0
                    let cellWidth: CGFloat = (screenWidth - cellMargin*2 - cellSpace*2)/3
                    let resizingProcessor = ResizingImageProcessor(referenceSize: CGSize(width: cellWidth, height: cellWidth))
                    
                    self.kf.setImage(with: resource, options: [.processor(resizingProcessor)])
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func setImage(with urlString: String, size: CGSize) {
        let cache = ImageCache.default
        cache.retrieveImage(forKey: urlString, options: nil) { result in // 캐시에서 키를 통해 이미지를 가져온다.
            switch result {
            case .success(let value):
                if let image = value.image {
                    // 캐시 이미지
                    self.image = image
                } else {
                    guard let url = URL(string: urlString) else { return }
                    let resource = ImageResource(downloadURL: url, cacheKey: urlString)
                    let resizingProcessor = ResizingImageProcessor(referenceSize: CGSize(width: size.width, height: size.height))
                    self.kf.setImage(with: resource, options: [.processor(resizingProcessor)])
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
