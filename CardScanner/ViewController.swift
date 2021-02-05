//
//  ViewController.swift
//  CardScanner
//
//  Created by Zheng on 2/4/21.
//

import UIKit
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBAction func pickImage(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        self.present(picker, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.borderWidth = 4
        imageView.layer.borderColor = UIColor.blue.cgColor
        imageView.contentMode = .scaleAspectFill
        
        imageView.backgroundColor = UIColor.green.withAlphaComponent(0.3)
        imageView.layer.masksToBounds = false /// allow image to overflow
        
    }
}

extension ViewController {
    func detectCard() {
        guard let cgImage = imageView.image?.cgImage else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            
            let request = VNDetectRectanglesRequest { request, error in
                /// this function will be called when the Vision request finishes
                self.handleDetectedRectangle(request: request, error: error)
            }
            
            request.minimumAspectRatio = 0.0
            request.maximumAspectRatio = 1.0
            request.maximumObservations = 1
            
            let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            
            do {
                try imageRequestHandler.perform([request])
            } catch let error {
                print("Error: \(error)")
            }
        }
    }
    
    func handleDetectedRectangle(request: VNRequest?, error: Error?) {
        if let results = request?.results {
            if let observation = results.first as? VNRectangleObservation {
                
                DispatchQueue.main.async {
                    guard let image = self.imageView.image else { return }
                    
                    let convertedRect = self.getConvertedRect(
                        boundingBox: observation.boundingBox,
                        inImage: image.size,
                        containedIn: self.imageView.bounds.size
                    )
                    self.drawBoundingBox(rect: convertedRect)
                }
            }
        }
    }
    func drawBoundingBox(rect: CGRect) {
        let uiView = UIView(frame: rect)
        for subView in imageView.subviews {
            subView.removeFromSuperview()
        }
        imageView.addSubview(uiView)
        
        uiView.backgroundColor = UIColor.clear
        uiView.layer.borderColor = UIColor.orange.cgColor
        uiView.layer.borderWidth = 3
    }
    
    func getConvertedRect(boundingBox: CGRect, inImage imageSize: CGSize, containedIn containerSize: CGSize) -> CGRect {
        
        let rectOfImage: CGRect
        
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        
        if imageAspect > containerAspect { /// image extends left and right
            let newImageWidth = containerSize.height * imageAspect /// the width of the overflowing image
            let newX = -(newImageWidth - containerSize.width) / 2
            rectOfImage = CGRect(x: newX, y: 0, width: newImageWidth, height: containerSize.height)
            
        } else { /// image extends top and bottom
            let newImageHeight = containerSize.width * (1 / imageAspect) /// the width of the overflowing image
            let newY = -(newImageHeight - containerSize.height) / 2
            rectOfImage = CGRect(x: 0, y: newY, width: containerSize.width, height: newImageHeight)
        }
        
        let newOriginBoundingBox = CGRect(
            x: boundingBox.origin.x,
            y: 1 - boundingBox.origin.y - boundingBox.height,
            width: boundingBox.width,
            height: boundingBox.height
        )
        
        var convertedRect = VNImageRectForNormalizedRect(newOriginBoundingBox, Int(rectOfImage.width), Int(rectOfImage.height))
        
        /// add the margins
        convertedRect.origin.x += rectOfImage.origin.x
        convertedRect.origin.y += rectOfImage.origin.y
        
        return convertedRect
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        imageView.image = image
        detectCard()
        
        dismiss(animated: true)
    }
}


