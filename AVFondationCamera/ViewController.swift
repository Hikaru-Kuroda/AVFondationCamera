//
//  ViewController.swift
//  AVFondationCamera
//
//  Created by 黑田光 on 2020/09/15.
//  Copyright © 2020 Hikaru Kuroda. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    var mainCamera: AVCaptureDevice?
    var innerCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice!
    
    var captureSession = AVCaptureSession()
    var photoOutput : AVCapturePhotoOutput?
    var cameraPreviewLayer : AVCaptureVideoPreviewLayer?
    
    //MARK: -UI
    let captureButton = UIButton()
    let zoomScaleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        captureSession.startRunning()
        
        setupCaptureButton()
        setupZoomScaleLabel()
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchedGesture(gestureRecgnizer:)))
        self.view.addGestureRecognizer(pinchGesture)
    }

    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices

        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                mainCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                innerCamera = device
            }
        }
        currentDevice = mainCamera
    }
    
    func setupInputOutput() {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
        } catch {
            print(error)
        }
    }
    
    func setupPreviewLayer() {
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.cameraPreviewLayer?.frame = view.frame
        self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
    }
    
    func setupCaptureButton() {
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 30
        //viewの子要素としてcaptureButtonを追加する
        self.view.addSubview(captureButton)
    
        //オートレイアウト　画面の下から-50, width: 60, height: 60
        //widthとheihgtを同じ値, cornerRadiusをその半分にすると綺麗な丸になる
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
        captureButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        captureButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        //タップされたときの処理を登録
        captureButton.addTarget(self, action: #selector(tappedCaptureButton(_:)), for: .touchUpInside)
    }

    
    //タップされたときの処理
    @objc func tappedCaptureButton(_ sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        self.photoOutput?.capturePhoto(with: settings, delegate: self as AVCapturePhotoCaptureDelegate)
    }
    
    func setupZoomScaleLabel() {
        zoomScaleLabel.textColor = .white
        zoomScaleLabel.font = UIFont.systemFont(ofSize: 20)
        zoomScaleLabel.isHidden = true
        self.view.addSubview(zoomScaleLabel)
        zoomScaleLabel.translatesAutoresizingMaskIntoConstraints = false
        zoomScaleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        zoomScaleLabel.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -40).isActive = true
    }
    
    var oldZoomScale: CGFloat = 1.0
    @objc func pinchedGesture(gestureRecgnizer: UIPinchGestureRecognizer) {
        do {
            try currentDevice.lockForConfiguration()
            let maxZoomScale: CGFloat = 6.0
            let minZoomScale: CGFloat = 1.0
            var currentZoomScale: CGFloat = currentDevice.videoZoomFactor
            let pinchZoomScale: CGFloat = gestureRecgnizer.scale
            zoomScaleLabel.isHidden = false
            
            if pinchZoomScale > 1.0 {
                currentZoomScale = oldZoomScale+pinchZoomScale-1
            } else {
                currentZoomScale = oldZoomScale-(1-pinchZoomScale)*oldZoomScale
            }

            if currentZoomScale < minZoomScale {
                currentZoomScale = minZoomScale
            }
            else if currentZoomScale > maxZoomScale {
                currentZoomScale = maxZoomScale
            }
            
            zoomScaleLabel.text = String(format: "%.1f", currentZoomScale)
            if gestureRecgnizer.state == .ended {
                oldZoomScale = currentZoomScale
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.zoomScaleLabel.isHidden = true
                }
                
            }

            currentDevice.videoZoomFactor = currentZoomScale
            currentDevice.unlockForConfiguration()
        } catch {
            return
        }
    }

}
extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            let uiImage = UIImage(data: imageData)
            UIImageWriteToSavedPhotosAlbum(uiImage!, nil,nil,nil)
        }
    }
}

