//
//  PostCell.swift
//  BeRealClone
//
//  Created by Chris on 5/3/23.
//

import UIKit
import Alamofire
import AlamofireImage

class PostCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var blurVisualEffectView: UIVisualEffectView!
    
    var imageDataRequest: DataRequest?
    
    func configure(with post: Post?) {
        postImageView.layer.cornerRadius = 9
        blurVisualEffectView.layer.cornerRadius = 9
        blurVisualEffectView.clipsToBounds = true
        
        if let user = post?.user {
            titleLabel.text = user.username
        }
        
        if let caption = post?.caption {
            captionLabel.text = caption
        }
        
        var infoLabelText: String?
        if let locationName = post?.locationString {
            infoLabelText = locationName + " · "
        }
        if let takenTime = post?.timeCreatedAt {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            
            infoLabelText? += timeFormatter.string(from: takenTime)
        }
        if infoLabelText != nil {
            infoLabel.text = infoLabelText
        }

        // Image
        if let imageFile = post?.imageFile,
           let imageUrl = imageFile.url {
            
            // Use AlamofireImage helper to fetch remote image from URL
            imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
                switch response.result {
                case .success(let image):
                    // Set image view image with fetched image
                    self?.postImageView.image = image
                case .failure(let error):
                    print("❌ Error fetching image: \(error.localizedDescription)")
                    break
                }
            }
        }
        
        if let currentUser = User.current, let lastPostedDate = currentUser.dateLastPostedAt, let postCreatedDate = post?.createdAt, let dateDifference = Calendar.current.dateComponents([.hour], from: postCreatedDate, to: lastPostedDate).hour {
            if abs(dateDifference) < 24 || post?.user == currentUser {
                blurVisualEffectView.isHidden = true
            }
            else {
                blurVisualEffectView.isHidden = false
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Reset image view image.
        postImageView.image = nil

        // Cancel image request.
        imageDataRequest?.cancel()
    }
    
}
