//
//  CameraViewController.swift
//  chineseOCR
//
//  Created by Tarun Kaushik on 23/06/18.
//  Copyright © 2018 Tarun Kaushik. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController{

    var captureSession:AVCaptureSession!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var stillImageOutput:AVCaptureStillImageOutput!
    @IBOutlet weak var previewView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var service = CustomVisionService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        
        captureButton.layer.cornerRadius = 40
        captureButton.clipsToBounds = true
        captureButton.layer.borderColor = UIColor.darkGray.cgColor
        captureButton.layer.borderWidth = 2

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionSetup()
    }
    
    func sessionSetup(){
        captureSession = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video) else{return}
        
        do{
            let input = try AVCaptureDeviceInput(device: device)
            captureSession.addInput(input)
        }catch{
            
            print("Error is found in input device try")
        }
        
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        
        if captureSession.canAddOutput(stillImageOutput){
            captureSession.addOutput(stillImageOutput)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer.frame = self.previewView.bounds
            previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            self.previewView.layer.addSublayer(previewLayer)
            
            self.captureSession.startRunning()
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func captureButtonAction(_ sender: Any) {
        
        guard captureButton.titleLabel?.text != "Try Again!" else{
            self.sessionSetup()
            self.captureButton.setTitle("CAPTURE AND FIND OUT", for: .normal)
            return
        }
        
        if let videoConnection = self.stillImageOutput.connection(with: .video){
            videoConnection.videoOrientation = .portrait
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) { (sampleBuffer, error) in
                if error != nil {
                    print(error?.localizedDescription)
                    return
                }
                
                if let sampleBuffer = sampleBuffer{
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider(data:imageData as! CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    
                    
                    let image = UIImage(cgImage: cgImageRef as! CGImage, scale: 1.0, orientation: UIImageOrientation.right)
                   
                    let CGimage = cgImageRef?.cropping(to: CGRect(x: image.size.width * 0.40, y:0, width: image.size.width, height: image.size.height))
                    let finalImage = UIImage(cgImage: CGimage!, scale: 1.0, orientation: UIImageOrientation.right)
                    
                    self.previewView.image = processImage(image: finalImage)
                    
                    self.captureSession.stopRunning()
                    self.captureButton.setTitle("Try Again!", for: .normal)
                    extractAction()
                }
            }
        }
        
        func extractAction() {
            resultLabel.text = ""
            self.activityIndicator.startAnimating()
            activityIndicator.isHidden = false
            
            
            guard let selectedImage = previewView.image?.scaleImage(640) else{return}
            let imageData = UIImageJPEGRepresentation(selectedImage, 0.8)!
            service.predict(image: imageData, completion: { (result: CustomVisionResult?, error: Error?) in
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                    
                    if let error = error {
                        self.resultLabel.text = error.localizedDescription
                    } else if let result = result {
                        let prediction = result.Predictions[0]
                        let probabilityLabel = String(format: "%.1f", prediction.Probability! * 100)
                        
                        self.resultLabel.text = "\(probabilityLabel)% sure this is \(prediction.Tag!)"
                    }
                }
            })
        }
        
        func processImage(image:UIImage) -> UIImage{
            let screenWidth = UIScreen.main.bounds.size.width
            
            let width:CGFloat = image.size.width
            let height:CGFloat = image.size.height
            
            print(width,height)
            
            let aspectRatio = screenWidth/width
            
            UIGraphicsBeginImageContextWithOptions(CGSize(width: screenWidth, height: screenWidth), false, 0.0)
            
            let ctx = UIGraphicsGetCurrentContext()
            
            ctx?.translateBy(x: 0, y: (screenWidth - (aspectRatio * height))*0.5)
            
            image.draw(in: CGRect(x: 0, y: 92.5, width: screenWidth, height: height * aspectRatio))
            
            UIGraphicsEndImageContext()
            
            previewView.image = image
            
            return previewView.image!
        }
        
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
