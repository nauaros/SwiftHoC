//
//  ViewController.swift
//  SwiftHoC
//
//  Created by Naufal Aros El Morabet on 11/12/2017.
//  Copyright © 2017 Naufal Aros. All rights reserved.
//

// TODO: https://developer.apple.com/machine-learning/

import UIKit
import CoreML


class ViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descripcion: UILabel!
    
    var modelo: Inceptionv3!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(seleccionarFoto))
        imageView.addGestureRecognizer(tapGestureRecognizer)
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 149.5
        imageView.layer.borderWidth = 3.0
        imageView.layer.borderColor = UIColor.white.cgColor
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        modelo = Inceptionv3()
    }

    @IBAction func seleccionarFoto(_ sender: Any) {
        
        let picker = UIImagePickerController()
        
        picker.allowsEditing = false
        picker.delegate = self
        
        picker.sourceType = .photoLibrary
        
        present(picker, animated: true)
    }
    
    @IBAction func tomarFoto(_ sender: Any) {
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        
        picker.sourceType = .camera
        
        present(picker, animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: UIImagePickerControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
        
        descripcion.text = "Cargando... desde el espacio"
        
        guard let imagen = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = imagen
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        imagen.draw(in: CGRect(x: 0, y:0, width: 299, height: 299))
        let nuevaImagen = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(nuevaImagen.size.width), Int(nuevaImagen
        .size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width:Int(nuevaImagen.size.width), height: Int(nuevaImagen.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: nuevaImagen.size.height)
        context?.scaleBy(x: 1, y: -1)
        
        UIGraphicsPushContext(context!)
        nuevaImagen.draw(in: CGRect(x: 0, y: 0, width: nuevaImagen.size.width, height: nuevaImagen.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        guard let concepto = try? modelo.prediction(image: pixelBuffer!) else {
            return
        }
        
        descripcion.text = "\(concepto.classLabel)"
    }
    
}

















