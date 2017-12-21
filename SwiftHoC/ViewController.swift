//
//  ViewController.swift
//  SwiftHoC
//
//  Created by Naufal Aros El Morabet on 11/12/2017.
//  Copyright © 2017 Naufal Aros. All rights reserved.
//

// PASOS A SEGUIR

// 2. Implementar los @IBOutlet de imageView y descripcion
// 3. Implementar los @IBAction las funciones "seleccionarFoto" y "realizarFoto" ()
// 4. Añadir extension donde se adapte "UIImagePickerControllerDelegate"
// 5. Añadir en el Info.plist el permiso para la camara ---> Privacy - Camera Usage Description

// 6. Descargar el modelo que vamos a utilizar (Inceptionv3) de "https://developer.apple.com/machine-learning/"
// 7 Añadir el modelo al proyecto (asegurarse de que Target esta marcado)
// 8. Ver la clase modelo que se genera a partir del modelo de machine learning (click en la flecha). Esta es la clase que vamos a utilizar para averiguar la descripción

// 9. Importamos CoreML. Se trata de la librería de la que hable antes.
// 10. Creamos una variable modelo de tipo Inceptionv3 (la clase modelo)
// 11. Inicializamos el modelo en viewWillAppear

// 12. Hay que convertir la imagen una de 299x299 (MODELO LO REQUIERE)

// 13. Obtener la descripcion de la imagen usando el modelo creado.

import UIKit

// 9. Importamos CoreML
import CoreML

class ViewController: UIViewController, UINavigationControllerDelegate {
    
    // 2. Implementar los @IBOutlet de imageView y descripcion
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descripcion: UILabel!
    
    // 10. Instancia del modelo
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
    
    // 11. Inicializamos el modelo
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        modelo = Inceptionv3()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // 3. Implementar los @IBAction las funciones "seleccionarFoto" y "realizarFoto" ()
    @IBAction func seleccionarFoto(_ sender: Any) {
        
        // Creamos una instancia de UIImagePickerController
        let picker = UIImagePickerController()
        
        picker.allowsEditing = false
        picker.delegate = self
        
        // Se indica que tome la foto de la libreria
        picker.sourceType = .photoLibrary
        
        //Mostramos la vista de la libreria
        present(picker, animated: true)
    }
    
    @IBAction func realizarFoto(_ sender: Any) {
        
        // UIImagePickerController es una clase que nos indica si el recurso de la camara esta disponible
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        // Creamos una instancia de UIImagePickerController
        let cameraPicker = UIImagePickerController()
        
        // Los métodos del delegado son llamados cuando se realiza la foto
        cameraPicker.delegate = self
        
        // Se indica que tome la foto de la camara
        cameraPicker.sourceType = .camera
        
        // Impedimos que el usuario pueda modificar la foto cuando la seleccione
        cameraPicker.allowsEditing = false
        
        // Mostramos la vista de la camara
        present(cameraPicker, animated: true)
    }
    
    
    
}

extension ViewController: UIImagePickerControllerDelegate {
    
    // Es llamado cuando el usuario cancela la operacion de tomar foto. Se elimina la vista de la libreria o camara
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // 12. Convertir la imagen
    
    // Este metodo es llamado cuando hemos finalizado de tomar la imagen.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        // Fijamos una descripcion es caso de que no haya cogido nada
        descripcion.text = "Cargando... desde el espacio"
        
        // 12.1 Obtener la imagen
        
        // La imagen se obtiene a partir de un diccionario con la clave "UIImagePickerControllerOriginalImage" (Indicar la manera de crear diccionarios)
        // El guard es como un assert de Java, se asegura de que se pueda obtener la imagen. En caso de que sea nil, entonces de sale de la funcion
        guard let imagen = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        }
        
        // Fijamos la imagen en el imageView
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = imagen
        
        // 12.2. Convertir la imagen a 299x299
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        imagen.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let nuevaImagen = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // 12.3. Transformar la imagen a un buffer de pixels de se almacenan en la memoria principal
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        // Se trata de una sintaxis heredada de Objective-C, todavia se utilizan direcciones de memoria
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(nuevaImagen.size.width), Int(nuevaImagen.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        // Obtenermos una referencia a la posicion donde se encuentra el buffer de pixels
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        // Se transforma los pixeles a un espacio de colores RGB y creamos un nuevo contexto para poder modificar
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(nuevaImagen.size.width), height: Int(nuevaImagen.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        // Convertimos la imagen a la altura de 299 y se escala
        context?.translateBy(x: 0, y: nuevaImagen.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        // Se genera la imagen y se elimina el context.
        UIGraphicsPushContext(context!)
        nuevaImagen.draw(in: CGRect(x: 0, y: 0, width: nuevaImagen.size.width, height: nuevaImagen.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        
        // 13. Obtenemos la descripcion de la imagen usando el pixelBuffer (no se puede pasar una imagen como tal)
        // Nos devuelve un objeto de tipo "Inceptionv3Output"
        guard let concepto = try? modelo.prediction(image: pixelBuffer!) else {
            return
        }
        
        // Indicamos en el label la descripcion del concepto
        descripcion.text = "\(concepto.classLabel)"
    }
}

















