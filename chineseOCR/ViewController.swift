//
//  ViewController.swift
//  chineseOCR
//
//  Created by Tarun Kaushik on 21/06/18.
//  Copyright © 2018 Tarun Kaushik. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressLabel: UILabel!
    var service = CustomVisionService()
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressLabel.text = ""
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.selectPic))
        tap.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tap)
        imageView.isUserInteractionEnabled = true
        
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true

    }


    @IBAction func extractButtonAction(_ sender: Any) {
        progressLabel.text = ""
        self.activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        
        guard imageView.image != #imageLiteral(resourceName: "Screen Shot 2018-06-21 at 5.20.57 PM") else{return}

        guard let selectedImage = imageView.image else{return}
        let imageData = UIImageJPEGRepresentation(selectedImage, 0.8)!
        service.predict(image: imageData, completion: { (result: CustomVisionResult?, error: Error?) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.activityIndicator.isHidden = true

                if let error = error {
                    self.progressLabel.text = error.localizedDescription
                } else if let result = result {
                    let prediction = result.Predictions[0]
                    let probabilityLabel = String(format: "%.1f", prediction.Probability! * 100)
                    
                    self.progressLabel.text = "\(probabilityLabel)% sure this is \(prediction.Tag!)"
                }
            }
        })
    }
    
    @objc func selectPic(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage,let scaledImage = image.scaleImage(640){
            imageView.image = scaledImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismissButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension UIImage {
    func scaleImage(_ maxDimension: CGFloat) -> UIImage? {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        
        if size.width > size.height {
            let scaleFactor = size.height / size.width
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            let scaleFactor = size.width / size.height
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        draw(in: CGRect(origin: .zero, size: scaledSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}


