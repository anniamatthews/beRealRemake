//
//  CreatePostViewController.swift
//  BeRealClone
//
//  Created by Chris on 5/3/23.
//

import UIKit
import PhotosUI
import ParseSwift
import CoreLocation

class CreatePostViewController: UIViewController, PHPickerViewControllerDelegate {
    
    var pickedImage: UIImage?
    var locationName: String?
    var createdTime: Date?
    var location: CLLocation?
        
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var captionText: UITextField!
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // When finished picking
        picker.dismiss(animated: true)
        
        let geocoder = CLGeocoder()
        
        guard let provider = results.first?.itemProvider,
           // Make sure the provider can load a UIImage
           provider.canLoadObject(ofClass: UIImage.self) else { return }

        let result = results.first
        
        if let assetId = result?.assetIdentifier {
            let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)

            createdTime = assetResults.firstObject?.creationDate
            //print(createdTime)
            self.location = assetResults.firstObject?.location
            //print(self.location)
          }
        
        // Load a UIImage from the provider
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            
            // Make sure we can cast the returned object to a UIImage
            guard let image = object as? UIImage else {
                
                // ❌ Unable to cast to UIImage
                self?.showCreatePostErrorAlert(description: "An image conversion has failed.")
                return
            }
            
            if let gottenLocation = self?.location {
                geocoder.reverseGeocodeLocation(gottenLocation) {
                    placemarks, error -> Void in
                    
                    if let locationName = placemarks?.first?.name {
                        self?.locationName = locationName
                        print(locationName)
                    }
                }
            }
            
            // Check for and handle any errors
            if let error = error {
                self?.showCreatePostErrorAlert(description: error.localizedDescription)
                return
            } else {
                // UI updates (like setting image on image view) should be done on main thread
                DispatchQueue.main.async {
                    
                    // Set image on preview image view
                    self?.previewImage.image = image
                    
                    // Set image to use when saving post
                    self?.pickedImage = image
                }
            }
        }
    }
    
    @IBAction func didTapPostButtonItem(_ sender: Any) {
        guard let image = pickedImage,
              // Create and compress image data (jpeg) from UIImage
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            return
        }

        // Create a ParseFile by providing a name and passing in the image data
        let imageFile = ParseFile(name: "image.jpg", data: imageData)

        // Create Post object
        var post = Post()

        // Set properties
        post.imageFile = imageFile
        post.caption = captionText.text
        post.locationString = self.locationName
        post.timeCreatedAt = self.createdTime
        
        // Set the user as the current user
        post.user = User.current

        // Save object in background (async)
        post.save { [weak self] result in

            // Switch to the main thread for any UI updates
            switch result {
                case .success(let post):
                    print("✅ Post Saved! \(post)")
                
                    if var currentUser = User.current {
                        currentUser.dateLastPostedAt = Date();
                        
                        currentUser.save { [weak self] result in
                            
                            switch result {
                                case .success(let user):
                                    print("✅ User Saved! \(user)")
                                
                                DispatchQueue.main.async {
                                    // Return to previous view controller
                                    self?.navigationController?.popViewController(animated: true)
                                }
                            case .failure(let error):
                                DispatchQueue.main.async {
                                    self?.showCreatePostErrorAlert(description: error.localizedDescription)
                                }
                            }
                            
                        }
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.showCreatePostErrorAlert(description: error.localizedDescription)
                    }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        previewImage.layer.cornerRadius = 12
        // CaptionTextField.tintColor = .lightGray
        captionText.attributedPlaceholder = NSAttributedString(string: "Add a caption...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])

        var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared()) // So assetIds are not nil
        config.filter = .images
        config.preferredAssetRepresentationMode = .current
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showCreatePostErrorAlert(description: String?) {
        let alertController = UIAlertController(title: "Unable to Create Post", message: description ?? "Unknown error", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }

}
