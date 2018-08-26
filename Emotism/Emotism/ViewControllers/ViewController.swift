//
//  ViewController.swift
//  Emotism
//
//  Created by Chris Mathias on 7/28/18.
//  Copyright © 2018 SolipsAR. All rights reserved.
//

import UIKit
import SceneKit
//import ARKit
import AVKit
import Vision
import CoreMLHelpers

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate { //}, ARSCNViewDelegate {

//    @IBOutlet var sceneView: ARSCNView!
    
    
    var screenFrameWidth:CGFloat!
    var screenFrameHeight:CGFloat!
    internal var backgroundLayer = CALayer()
    
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Detecting"
        label.font = label.font.withSize(30)
        return label
    }()
    
    let feedbackView: UIImageView = {
        let feedbackView = UIImageView()
        return feedbackView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpModel()

        screenFrameWidth = view.frame.width
        screenFrameHeight = view.frame.height
        
        print("screenFrameWidth: \(screenFrameWidth)")
        print("screenFrameHeight: \(screenFrameHeight)")

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high  //capture type?
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return
        }
        
        captureSession.addInput(input)
        captureSession.startRunning()
        

        let dataOutput = AVCaptureVideoDataOutput()
        guard captureSession.canAddOutput(dataOutput) else {
            return
        }

        captureSession.addOutput(dataOutput)
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MLProcessorQueue"))
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        // connection
        let connection = dataOutput.connection(with: .video)
        connection?.videoOrientation = .portrait

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        previewLayer.addSublayer(backgroundLayer)
        
        previewLayer.name = "camera"
        previewLayer.frame.size = CGSize(width: view.frame.width/2, height:view.frame.height/2)
        previewLayer.frame.origin = CGPoint(x: view.frame.height/2, y: view.frame.width/2)

        //        if IS_DEBUG {
            print("VideoService: size of previewLayer")
            print(previewLayer.frame.size)
//        }
        previewLayer.position = CGPoint(x: view.frame.width/2, y: view.frame.height/2)
        
        view.layer.insertSublayer(previewLayer, below: view.layer)// (previewLayer)
        
        previewLayer.insertSublayer(self.backgroundLayer, above: previewLayer)
        
        print("previewLayer: \(previewLayer.frame.width)")
        print("previewLayer: \(previewLayer.frame.height)")

        
        view.addSubview(label)
        view.addSubview(feedbackView)
        setupLabel()
        setupFeedbackView()
        
//        // Set the view's delegate
//        sceneView.delegate = self
//
//        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
//
//        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
//
//        // Set the scene to the view
//        sceneView.scene = scene
    }
    
    //TODO:
    /**
        1. Modify the image capture to identify a face and get bounding box
        2. Modify the ML processor to use emotion detection alg
        3. Pass the image capture by slicing the "box" and passing to the alg
        4. Annotate the face with the identified emotion
        5. Tie the labeling of the face/emotion to the spatial location of the face
 
    **/
    
    
    //MARK: - Delegate method for av capture. Start ML processing
    var emotionDetectionModel:VNCoreMLModel!
    var isRunningEmotionQuery = false
    
    func setupLabel() {
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }
    func setupFeedbackView() {
        feedbackView.frame = CGRect(x:0,y:0,width:100,height:100)
        feedbackView.contentMode = .scaleAspectFit
        feedbackView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        feedbackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }
    
    func setUpModel() {
        do {
            emotionDetectionModel = try VNCoreMLModel(for: harshsikka_big().model)
            
            // Allocate this pixel buffer just once and keep reusing it:
            resizedPixelBuffer = createPixelBuffer(width: 48, height: 48)
            
        } catch {
            print("Error setting up model", error)
        }
    }
    
    var frameIdx = 0
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("camerea was able to capture a frame", Date())
        
        
        
        /***
         let ratio = image.size.width / image.size.height
         if containerView.frame.width > containerView.frame.height {
         let newHeight = containerView.frame.width / ratio
         imageView.frame.size = CGSize(width: containerView.frame.width, height: newHeight)
         }
         else{
         let newWidth = containerView.frame.height * ratio
         imageView.frame.size = CGSize(width: newWidth, height: containerView.frame.height)
         }
 **/
        
//        if (frameIdx % 10 == 0) {
            //Probably a very hacky way to cut back on frame rate here.
            //
//            print("callback for video capture delegate invoked. frame: \(frameIdx)")
            handle(buffer: sampleBuffer)
//        }
//        frameIdx += 1
        
    }
    
    func handle(buffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {
            return
        }
        
        if isRunningEmotionQuery {
            
            print("Skipping frame")
            return
            
        } //Don't double pump, skip this frame.
        
        makeFaceDetectionRequest(pixelBuffer: pixelBuffer)
    }
    
    
    
    let ciContext = CIContext()
    
    var resizedPixelBuffer: CVPixelBuffer?
    
    func makeFaceDetectionRequest(pixelBuffer: CVPixelBuffer) {
        
        let faceDetectReqHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: CGImagePropertyOrientation.up,
            options: [VNImageOption: Any]()
        )
        
        //Find faces in the pixel buffer
        let faceDetectRequest = VNDetectFaceRectanglesRequest { (req, err) in
            
//            print("Face detect request made")
            if let err = err {
                print("failed to detect faces:", err)
                return
            }
            
            guard let results = req.results else {
                //No face found, remove the box
                print("No faces found")

                return
            }
            
//            print("\(results.count) faces found")

            results.forEach({ (res) in
                
                guard let face = res as? VNFaceObservation else {
                    return
                }
                
                let imageToCrop = CIImage(cvImageBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.up)
                
//                print("imageToCrop.extent.width: \(imageToCrop.extent.width)")
//                print("imageToCrop.extent.height: \(imageToCrop.extent.height)")

                //Bounding box of face becomes crop rect details
                let x = self.screenFrameWidth * face.boundingBox.origin.x
                let y = self.screenFrameHeight * face.boundingBox.origin.y
                let width = self.screenFrameWidth * face.boundingBox.width
                let height = self.screenFrameHeight * face.boundingBox.height
                
                let cropRect = CGRect(x: x, y: y, width: width, height: height)
//                print("point-based-face-crop-rect: \(cropRect)")
                

                //Crop rect (in points) becomes pixel-based for cropping
                //https://developer.apple.com/documentation/coregraphics/cgimage/1454683-cropping
                let imageViewScale = max(imageToCrop.extent.width / self.screenFrameWidth,
                                         imageToCrop.extent.height / self.screenFrameHeight)

                let cropZone = CGRect(x:cropRect.origin.x * imageViewScale,
                                      y:cropRect.origin.y * imageViewScale,
                                      width:cropRect.size.width * imageViewScale,
                                      height:cropRect.size.height * imageViewScale)
                
//                print("pixel-based-face-crop-rect: \(cropZone)")

                //What if this is not square how do we force it to be?(crop to center)
                let faceCropped = imageToCrop.cropped(to: cropZone)
                
                let cgImage = self.ciContext.createCGImage(faceCropped, from: faceCropped.extent)
                
//                UIImage(pixelBuffer: resizedPixelBuffer)
                //http://machinethink.net/blog/help-core-ml-gives-wrong-output/
//                let cgImage = self.ciContext.createCGImage(faceCropped, from: faceCropped.extent, format: CIFormat., colorSpace: CGColorSpace.linearGray)

                let theFace = UIImage(cgImage: cgImage!)
                // To resize your CVPixelBuffer:
                if let facePixelBuffer = theFace.pixelBufferGray(width: 64, height: 64) {
                    
//                    resizePixelBuffer(facePixelBuffer, width: 48, height: 48,
//                                      output: resizedPixelBuffer, context: self.ciContext)
//
                    let emotionDetectReqHandler = VNImageRequestHandler(cvPixelBuffer: facePixelBuffer,
                                                                        orientation: CGImagePropertyOrientation.up,
                                                                        options: [VNImageOption: Any]())
                    
                    let emotionLabelRequest = VNCoreMLRequest(model: self.emotionDetectionModel) { (finishedReq, err) in
                        
                        guard let results = finishedReq.results as? [VNClassificationObservation] else {
                            return
                        }
                        
                        guard let firstObservation = results.first else {
                            return
                        }
                        
                        print(firstObservation.identifier, firstObservation.confidence)
                        
                        DispatchQueue.main.async(execute: {
                            self.feedbackView.image = UIImage(ciImage: CIImage(cvPixelBuffer: facePixelBuffer))
                            self.label.text = "\(firstObservation.identifier)"
                        })
                        self.isRunningEmotionQuery = false
                        
                    }
                    
                    //                DispatchQueue.global(qos: .background).async {
                    do {
                        self.isRunningEmotionQuery = true
                        try emotionDetectReqHandler.perform([emotionLabelRequest])
                    } catch let reqErr {
                        self.isRunningEmotionQuery = false
                        print("Failed to perform request:", reqErr)
                    }
                    //                }
                }
                
            })
            
        }
        
//        DispatchQueue.global(qos: .background).async {
            do {
                try faceDetectReqHandler.perform([faceDetectRequest])
            } catch let reqErr {
                print("Failed to perform request:", reqErr)
            }
//        }
        
        
    }
    
//    var redView:UIView!
//
//    func updateFaceBox(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
//        if (redView == nil) {
//            redView = UIView()
//            redView.backgroundColor = .red
//            redView.alpha = 0.4
//            self.view.addSubview(redView)
//        } else {
//            redView.frame = CGRect(x: x, y: y, width: width, height: height)
//        }
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        // Create a session configuration
//        let configuration = ARWorldTrackingConfiguration()
//
//        // Run the view's session
//        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        // Pause the view's session
//        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
//    func session(_ session: ARSession, didFailWithError error: Error) {
//        // Present an error message to the user
//        
//    }
//    
//    func sessionWasInterrupted(_ session: ARSession) {
//        // Inform the user that the session has been interrupted, for example, by presenting an overlay
//        
//    }
//    
//    func sessionInterruptionEnded(_ session: ARSession) {
//        // Reset tracking and/or remove existing anchors if consistent tracking is required
//        
//    }
}
