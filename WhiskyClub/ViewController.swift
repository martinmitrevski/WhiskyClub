//
//  ViewController.swift
//  WhiskyClub
//
//  Created by Martin Mitrevski on 13.04.18.
//  Copyright © 2018 Mitrevski. All rights reserved.
//

import UIKit
import VisualRecognitionV3

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var detectedWhisky: UILabel!
    @IBOutlet weak var detectedHeader: UILabel!
    
    private let apiKey = "737fbf732dc6b088fd4db5400610c825df00cf8b"
    private let classifierId = "WhiskyRecognizer_646540482"
    private let version = "2017-12-07"
    var visualRecognition: VisualRecognition!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.detectedHeader.text = ""
        self.visualRecognition = VisualRecognition(apiKey: apiKey, version: version)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let localModels = try? visualRecognition.listLocalModels()
        if let models = localModels, models.contains(self.classifierId)  {
            print("local model found")
        } else {
            self.updateModel()
        }
    }

    @IBAction func selectWhiskyImageTapped(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
    //MARK: - Model Methods
    
    func updateModel()
    {
        let failure = { (error: Error) in
            print(error)
        }
        
        let success = {
            print("model updated")
        }
        
        visualRecognition.updateLocalModel(classifierID: classifierId,
                                           failure: failure,
                                           success: success)
    }
    
    @IBAction func updateModelTapped(_ sender: UIButton) {
        self.updateModel()
    }
    
    // MARK: - Photo picker
    
    func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    // MARK: - Whisky classification
    
    func classifyImage(for image: UIImage, localThreshold: Double = 0.0) {

        detectedWhisky.text = "Detecting whisky..."

        let failure = { (error: Error) in
            self.showAlert("Could not classify image", alertMessage: error.localizedDescription)
        }

        visualRecognition.classifyWithLocalModel(image: image,
                                                 classifierIDs: [classifierId],
                                                 threshold: localThreshold,
                                                 failure: failure) { classifiedImages in

            var topClassification = ""

            if classifiedImages.images.count > 0 && classifiedImages.images[0].classifiers.count > 0 && classifiedImages.images[0].classifiers[0].classes.count > 0 {
                topClassification = classifiedImages.images[0].classifiers[0].classes[0].className
            }
            
            var detectedText = "Unrecognized whisky. Are you sure it's not Cognac?"
            let whiskyInfo = WhiskyService.shared.whiskyInfo(forLabel: topClassification)
            if let name = whiskyInfo["name"] as? String {
                detectedText = name
            }

            DispatchQueue.main.async {
                self.detectedHeader.text = "Detected whisky"
                self.detectedWhisky.text = "\(detectedText)"
            }
        }
    }
    
    //MARK: - Alerts
    func showAlert(_ alertTitle: String, alertMessage: String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage,
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Handling Image Picker Selection
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        imageView.image = image
        classifyImage(for: image, localThreshold: 0.2)
    }
}
