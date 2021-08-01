//
//  ViewController.swift
//  ImageSearch
//
//  Created by Dabeeo on 2021/07/30.
//

import UIKit
import Alamofire
import SwiftyJSON
class ViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    //선택 화면 이미지에 보여질 UI
    @IBOutlet weak var selectView : UIView!
    @IBOutlet weak var selectScroll : UIScrollView!
    @IBOutlet weak var siteNameLabel : UILabel!
    @IBOutlet weak var dateTimeLabel : UILabel!
    var selectImageView = UIImageView()
    
    
    private var page: Int = 1
    private var totalCount: Int = 0
    private var imageUrlList: [String] = []
    private var imageInfoList :[ImageData] = []
    private var paging: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initUI()
        // Do any additional setup after loading the view.
    }


    func initUI() {
        let backButton = UIButton()
        backButton.addTarget(self, action: #selector(back(sender:)), for: .touchUpInside)
        selectScroll.isScrollEnabled = true
        selectImageView.frame = self.view.frame
        backButton.frame = self.view.frame
        selectScroll.addSubview(selectImageView)
        selectScroll.addSubview(backButton)
    }
}
// MARK: - Networks
extension ViewController{
    private func getImagesNetwork(keyword:String, page:Int, size: Int) {
        indicator.startAnimating()
        self.searchBar.resignFirstResponder()
        var url = Constants.DAPI_URL + "?query=\(keyword)&page=\(page)&size=\(size)"
        url = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        AF.request(url, method: .get, encoding: JSONEncoding.default, headers: ["Authorization": Constants.AUTHORIZATION]).responseJSON { [weak self] (response) in
            switch (response.result) {
            case .success(let json):
                self?.indicator.stopAnimating()
                let jsonString = String(describing: json)
                let jsonData = JSON(json)
                
                self?.totalCount = jsonData["meta"]["total_count"].intValue
                
                if self?.totalCount == 0 && self?.searchBar.text != "" {
                    self?.emptyLabel.isHidden = false
                } else {
                    self?.emptyLabel.isHidden = true
                }
                
                for data in jsonData["documents"].arrayValue {
                    let imgD = ImageData()
                    imgD.display_sitename = data["display_sitename"].stringValue
                    imgD.datetime = data["datetime"].stringValue
                    imgD.thumbnail_url = data["thumbnail_url"].stringValue
                    imgD.image_url = data["image_url"].stringValue
                    imgD.height = data["height"].intValue
                    imgD.width = data["width"].intValue
                    self?.imageUrlList.append(data["thumbnail_url"].stringValue)
                    self?.imageInfoList.append(imgD)
                }
                
                self?.paging = true
                self?.collectionView.reloadData()
            case .failure(let error):
                self?.indicator.stopAnimating()
                print("Network Error: \(error)")
            }
        }
    }
}

// MARK: - Action
extension ViewController {
    @objc func back(sender: UIButton) {
        self.selectView.isHidden = true
        //캐쉬 삭제가 필요한 경우 삭제
    }
    @objc func clickButton(sender: UIButton) {
        self.searchBar.resignFirstResponder()
        let selectImage = imageInfoList[sender.tag]

        siteNameLabel.text = selectImage.display_sitename
        dateTimeLabel.text = selectImage.datetime
        
        let screenWidth : CGFloat = UIScreen.main.bounds.width
        let screenHeight : CGFloat = UIScreen.main.bounds.height
        let nHeight = (Int(screenWidth) * selectImage.height!) / selectImage.width!
        let nSize = CGSize(width: screenWidth, height: CGFloat(nHeight))
        if screenHeight -  self.view.safeAreaInsets.top < CGFloat(nHeight) {
            selectScroll.contentSize = nSize
        }
        self.selectImageView.frame.size = nSize
        self.selectImageView.setImage(with: selectImage.image_url!, size: nSize)
        self.selectView.isHidden = false
    }
}

// MARK: - CollectionView Delegate
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageUrlList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as! ImageCollectionViewCell
        
        guard indexPath.row < self.imageUrlList.count  else {
            return cell
        }
        cell.button.tag = indexPath.row
        cell.button.addTarget(self, action: #selector(clickButton(sender:)), for: .touchUpInside)
        cell.imageView.setThumbImage(with: self.imageUrlList[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let screenWidth = UIScreen.main.bounds.width
        let cellMargin: CGFloat = 20.0
        let cellSpace: CGFloat = 10.0
        let cellWidth: CGFloat = (screenWidth - cellMargin*2 - cellSpace*2)/3
        
        let cellSize = CGSize(width: cellWidth, height: cellWidth)
        return cellSize
    }
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if distanceFromBottom < height, self.paging {
            //Scroll Bottom
            self.paging = false
            guard self.imageUrlList.count < self.totalCount else {
                return
            }
            self.page += 1
            self.getImagesNetwork(keyword: self.searchBar.text ?? "", page: self.page, size: Constants.SIZE)
        }
    }
}

// MARK: - UISearchBar Delegate
extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        imageUrlList.removeAll()
        imageInfoList.removeAll()
        page = 1
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(ViewController.reload), object: nil)
        self.perform(#selector(ViewController.reload), with: nil, afterDelay: 1.0)
    }
    
    @objc func reload() {
        guard let searchText = self.searchBar.text else { return }
        self.getImagesNetwork(keyword: searchText, page: self.page, size: Constants.SIZE)
    }
}
