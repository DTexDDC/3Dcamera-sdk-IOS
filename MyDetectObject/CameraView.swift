import SwiftUI
import AVFoundation
import TensorFlowLiteTaskVision
import Vision
import CoreImage

//struct CameraView: UIViewRepresentable, DetectDelegate {
//    private var session = AVCaptureSession()
//    private let coordinator = CameraCoordinator()
//    @Binding var objectDetect: [ObjectDetect]
//    @EnvironmentObject var objectDetectionHelper: ObjectDetectionHelper
//
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView(frame: .zero)
//        coordinator.delegate = self
//        coordinator.view = view
////        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
////        previewLayer.videoGravity = .resizeAspect
////        view.layer.addSublayer(previewLayer)
////            
////        DispatchQueue.main.async {
////            print(view.bounds)
////            previewLayer.frame = view.bounds
//            
//            // Set up the button view
////            let switchCameraView = SwitchCameraView(frame: CGRect(x: 0, y: 0, width: 160, height: 60))
////            view.translatesAutoresizingMaskIntoConstraints = false
////            view.addSubview(switchCameraView)
////            
////            // Add Auto Layout constraints
////            NSLayoutConstraint.activate([
////    //            switchCameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
////                switchCameraView.widthAnchor.constraint(equalToConstant: 60),
////                switchCameraView.heightAnchor.constraint(equalToConstant: 160)
////            ])
//            
////            configureSessionAndStartRunning()
////        }
//
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {
//        
////        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
////            DispatchQueue.main.async {
////                previewLayer.frame = uiView.bounds
////            }
////        }
//    }
//
//    func startSession() {
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.session.startRunning()
//        }
//    }
//
//    func stopSession() {
//        session.stopRunning()
//    }
//
////    func configureSession() {
////        session.beginConfiguration()
//////        session.sessionPreset = .photo
////
////        if let camera = AVCaptureDevice.default(
////            .builtInDualWideCamera,
////            for: .video,
////            position: .back) {
////            if let input = try? AVCaptureDeviceInput(device: camera) {
////                session.addInput(input)
////                }
////        }
////
//////        let videoOutput = AVCaptureVideoDataOutput()
////        let videoOutput = AVCapturePhotoOutput()
////        guard session.canAddOutput(videoOutput) else { return }
////        session.sessionPreset = .photo
////        session.addOutput(videoOutput)
//////        videoOutput.setSampleBufferDelegate(coordinator, queue: DispatchQueue(label: "sampleBufferQueue"))
//////        videoOutput.alwaysDiscardsLateVideoFrames = true
//////        videoOutput.videoSettings = [ String(kCVPixelBufferPixelFormatTypeKey) : kCMPixelFormat_32BGRA]
//////        if session.canAddOutput(videoOutput) {
//////            session.addOutput(videoOutput)
//////            videoOutput.connection(with: .video)?.videoOrientation = .portrait
//////        }
//////        
////        session.commitConfiguration()
////    }
//    
////    func setupSwitchCameraView(view: UIView) {
////        let switchView = SwitchCameraView(frame: CGRect(x: 50, y: 50, width: 160, height: 60))
////        switchView.translatesAutoresizingMaskIntoConstraints = false
////        view.addSubview(switchView)
////        
////    }
//     
//    func didUpdateBoundingBoxes(_ objectDetect: [ObjectDetect]) {
////        print("Data updated: \(data)")
////        print("-----")
////        print(boundingBoxes)
//        self.objectDetect = objectDetect
//    }
//
////    func configureSessionAndStartRunning() {
////        configureSession()
////        startSession()
////    }
//
//    func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer, to targetSize: CGSize) -> CVPixelBuffer? {
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        
//        let scaleX = targetSize.width / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
//        let scaleY = targetSize.height / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
//        let scale = min(scaleX, scaleY)
//        
//        let resizedCIImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
//        
//        let ciContext = CIContext()
//        
//        var newPixelBuffer: CVPixelBuffer?
//        let pixelBufferAttributes: [String: Any] = [
//            kCVPixelBufferCGImageCompatibilityKey as String: true,
//            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
//        ]
//        CVPixelBufferCreate(kCFAllocatorDefault, Int(targetSize.width), Int(targetSize.height),
//                            kCVPixelFormatType_32BGRA, pixelBufferAttributes as CFDictionary, &newPixelBuffer)
//        
//        guard let outputPixelBuffer = newPixelBuffer else {
//            return nil
//        }
//        
//        ciContext.render(resizedCIImage, to: outputPixelBuffer)
//        
//        return outputPixelBuffer
//    }
//    
//    func pixelBufferToUIImage(pixelBuffer: CVPixelBuffer){
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let context = CIContext()
//        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
//            objectDetectionHelper.imagePreview = UIImage(cgImage: cgImage)
//        }
//    }
//
//    
//    func detect(pixelBuffer: CVPixelBuffer) {
//        pixelBufferToUIImage(pixelBuffer: pixelBuffer)
////        guard let overlayView = self.coordinator.view else { return }
////        guard let pixelBuffer = resizePixelBuffer(pixelBuffer, to: overlayView.bounds.size) else {
////            print("Failed to resize pixel buffer.")
////            return
////        }
//        var result = objectDetectionHelper.detect(frame: pixelBuffer)
//
//      guard let displayResult = result else {
//        return
//      }
//
//      let width = CVPixelBufferGetWidth(pixelBuffer)
//      let height = CVPixelBufferGetHeight(pixelBuffer)
//
//      DispatchQueue.main.async {
//
//        // Display results by handing off to the InferenceViewController
////        self.inferenceViewController?.resolution = CGSize(width: width, height: height)
//
//        var inferenceTime: Double = 0
////        self.inferenceViewController?.inferenceTime = inferenceTime
////        self.inferenceViewController?.tableView.reloadData()
//
//        // Draws the bounding boxes and displays class names and confidence scores.
//          self.coordinator.drawAfterPerformingCalculations(
//          onDetections: displayResult,
//          withImageSize: CGSize(width: CGFloat(width), height: CGFloat(height)))
//      }
//    }
//}
//
//class CameraCoordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
//    private var isInferenceQueueBusy = false
//    private let inferenceQueue = DispatchQueue(label: "org.tensorflow.lite.inferencequeue")
//    
//    var delegate: DetectDelegate?
//    var view: UIView?
//    private let edgeOffset: CGFloat = 2.0
//    private let labelOffset: CGFloat = 10.0
////    var previousBoxes: [CGRect] = []
//    
//    struct TrackedBox {
//        var id: Int
//        var boundingBox: CGRect
//    }
//
//    var trackedBoxes: [TrackedBox] = []
//    var nextID = 0
//
//    // Delegate to handle the video frame
//    func captureOutput(_ output: AVCaptureOutput,
//                       didOutput sampleBuffer: CMSampleBuffer,
//                       from connection: AVCaptureConnection) {
//        let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)
//        guard let imagePixelBuffer = pixelBuffer else {
//          return
//        }
//        didOutput(pixelBuffer: imagePixelBuffer)
//    }
//    
//    func didOutput(pixelBuffer: CVPixelBuffer) {
//        // Drop current frame if the previous frame is still being processed.
//        guard !self.isInferenceQueueBusy else { return }
//        inferenceQueue.async {
//            self.isInferenceQueueBusy = true
//            self.delegate?.detect(pixelBuffer: pixelBuffer)
//            self.isInferenceQueueBusy = false
//        }
//    }
//    
//    func filterOverlappingBoxes(_ boxes: [ObjectDetect]) -> [ObjectDetect] {
////        var filteredBoxes = boxes
////        
////        for (i, boxA) in boxes.enumerated() {
////            for (j, boxB) in boxes.enumerated() {
////                if i != j, boxA.boundingBoxes.area > boxB.boundingBoxes.area,
////                   boxA.boundingBoxes.mostlyContains(boxB.boundingBoxes) {
////                    filteredBoxes.removeAll { $0 === boxB }
////                }
////            }
////        }
//        
//        return filteredBoxes
//    }
//    
//    func convertBoundingBox(_ detection: Detection, from imageSize: CGSize, to viewSize: CGSize) -> CGRect {
//        let scaleX = viewSize.width / detection.boundingBox.width
//        let scaleY = viewSize.height / detection.boundingBox.height
//        return CGRect(
//            x: detection.boundingBox.origin.x * scaleX,
//            y: detection.boundingBox.origin.y * scaleY,
//            width: detection.boundingBox.width * scaleX,
//            height: detection.boundingBox.height * scaleY
//        )
//    }
//    
//    func logScreen() {
//        let screenSize = UIScreen.main.bounds
//        let screenWidth = screenSize.width
//        let screenHeight = screenSize.height
//
//        print("Chiều rộng màn hình: \(screenWidth)")
//        print("Chiều cao màn hình: \(screenHeight)")
//    }
//    
//    func drawAfterPerformingCalculations(onDetections detections: [ObjectDetect], withImageSize imageSize: CGSize) {
//        var newTrackedBoxes: [TrackedBox] = []
//        var boxs: [ObjectDetect] = []
//        
//        for detection in detections {
////            guard let category = detection.categories.first else { continue }
////            guard let overlayView = self.view else { continue }
////
////            var convertedRect = detection.boundingBox.applying(
////                CGAffineTransform(
////                    scaleX: overlayView.bounds.size.width / imageSize.width,
////                    y: overlayView.bounds.size.height / imageSize.height))
////            
////            print("\(overlayView.bounds.size.width) \(overlayView.bounds.size.height) | \(imageSize.width) \(imageSize.height) | \(detection.boundingBox.width) \(detection.boundingBox.height) | \(detection.boundingBox.origin.x) \(detection.boundingBox.origin.y) ")
//
//            convertedRect.origin.x = max(self.edgeOffset, convertedRect.origin.x)
//            convertedRect.origin.y = max(self.edgeOffset, convertedRect.origin.y)
//            convertedRect.size.width = min(overlayView.bounds.maxX - convertedRect.origin.x - self.edgeOffset, convertedRect.size.width)
//            convertedRect.size.height = min(overlayView.bounds.maxY - convertedRect.origin.y - self.edgeOffset, convertedRect.size.height)
//
//            let closestTrackedBox = trackedBoxes.min(by: {
//                $0.boundingBox.distance(to: convertedRect) < $1.boundingBox.distance(to: convertedRect)
//            })
//
//            let id: Int
//            if let closestBox = closestTrackedBox, closestBox.boundingBox.distance(to: convertedRect) < 30 { 
//                id = closestBox.id
//            } else {
//                id = nextID
//                nextID += 1
//            }
//
//            print("\(category.index) | \(category.score) | \(category.description) | \(category.label) | \(category.displayName) | \(category.hashValue) | \(category.hash)")
//
//
//            newTrackedBoxes.append(TrackedBox(id: id, boundingBox: convertedRect))
//
//            let objectDescription = String(format: "\(category.label ?? "Unknown") (%.2f)", category.score)
//            var item = ObjectDetect()
//            item.boundingBoxes = convertedRect
//            item.label = "\(objectDescription) - ID \(id)"
//            boxs.append(item)
//        }
//
//        trackedBoxes = newTrackedBoxes
//        
//        boxs = filterOverlappingBoxes(boxs)
//        
//        delegate?.didUpdateBoundingBoxes(boxs)
//    }
//}
//
protocol DetectDelegate {
    func didUpdateBoundingBoxes(_ objectDetect: [ObjectDetect])
    func detect(pixelBuffer: CVPixelBuffer)
}

/// TFLite model types
enum ModelType: CaseIterable {
//  case efficientDetLite0
//  case efficientDetLite1
//  case efficientDetLite2
//  case ssdMobileNetV1
//  case nerfModel
//  case healthysnacksV2
//  case healthysnacksV3
//  case yolov8_f16
//  case yolo11n_float32
//    case healthysnacksV5
//    case Final_TFL
//    case v3_nerf_guns
//    case v4_nerf_guns
//    case yolo_trial
    case tins
    case snacks_yolo
    
    var modelFileInfo: FileInfo {
      switch self {
//      case .ssdMobileNetV1:
//        return FileInfo("ssd_mobilenet_v1", "tflite")
//      case .efficientDetLite0:
//        return FileInfo("efficientdet_lite0", "tflite")
//      case .efficientDetLite1:
//        return FileInfo("efficientdet_lite1", "tflite")
//      case .efficientDetLite2:
//        return FileInfo("efficientdet_lite2", "tflite")
//      case .nerfModel:
//        return FileInfo("nerf_model-1", "tflite")
//      case .healthysnacksV2:
//        return FileInfo("ire-healthysnacks-product-on-scene-tfl-v2", "tflite")
//      case .healthysnacksV3:
//        return FileInfo("ire-healthysnacks-product-on-scene-tfl-v3", "tflite")
//      case .yolov8_f16:
//          return FileInfo("yolov8s_float16", "tflite")
//      case .yolo11n_float32:
//        return FileInfo("yolo11n_float32", "tflite")
//      case .healthysnacksV5:
//          return FileInfo("ire-healthysnacks-product-on-scene-tfl-v5", "tflite")
//      case .Final_TFL:
//          return FileInfo("tfl_27", "tflite")
//      case .v3_nerf_guns:
//          return FileInfo("nerf_guns_product_on_scene_tfl_detector_v3", "tflite")
//          
//      case .v4_nerf_guns:
//          return FileInfo("nerf_guns_product_on_scene_tfl_detector_v4", "tflite")
//      case .yolo_trial:
//          return FileInfo("model", "tflite")
      case .tins:
          return FileInfo("tinned-food-product-on-scene-tfl-v1b_float32", "tflite")
      case .snacks_yolo:
          return FileInfo("output_float32", "tflite")
//
      }
    }

    var title: String {
        switch self {
            //      case .ssdMobileNetV1:
            //        return "SSD-MobileNetV1"
            //      case .efficientDetLite0:
            //        return "EfficientDet-Lite0"
            //      case .efficientDetLite1:
            //        return "EfficientDet-Lite1"
            //      case .efficientDetLite2:
            //        return "EfficientDet-Lite2"
            //      case .nerfModel:
            //        return "nerf_model-1"
            //      case .healthysnacksV2:
            //        return "HealthySnacks-Produce-Model-V2"
            //      case .healthysnacksV3:
            //        return "HealthySnacks-Produce-Model-V3"
            //      case .yolov8_f16:
            //          return "yolov8s_float16"
            //      case .yolo11n_float32:
            //        return "yolo11n_float32"
            //      case .healthysnacksV5:
            //          return "HealthySnacks-V5"
//        case .Final_TFL:
//            return "Final-TFL"
//        case .v3_nerf_guns:
//            return "v3_nerf_guns"
//        case .v4_nerf_guns:
//            return "v4_nerf_guns"
//        case .yolo_trial:
//            return "yolo_trial"
        case .tins:
            return "tins"
        case .snacks_yolo:
            return "snacks_yolo"
        }
    }
  }
/// Default configuration
struct ConstantsDefault {
    static let modelType: ModelType = .snacks_yolo
    static let jsonType = "output_float32_labels" //Not json should be text format.
  static let threadCount = 2
  static let scoreThreshold: Float = 0.5
  static let maxResults: Int = 100
  static let theadCountLimit = 2
}

extension CGRect {

    func distance(to other: CGRect) -> CGFloat {
        let dx = (self.midX - other.midX)
        let dy = (self.midY - other.midY)
        return sqrt(dx * dx + dy * dy)
    }

    func intersectionArea(with other: CGRect) -> CGFloat {
        let intersectionRect = self.intersection(other)
        return intersectionRect.isNull ? 0 : intersectionRect.width * intersectionRect.height
    }
    

    func mostlyContains(_ other: CGRect, threshold: CGFloat = 0.7) -> Bool {
        let intersectionArea = self.intersectionArea(with: other)
        return intersectionArea / other.area > threshold
    }
    
    var area: CGFloat {
        return self.width * self.height
    }
    
    func intersectionRatio(rect2: CGRect) -> CGFloat {
        let intersection = self.intersection(rect2)

        if intersection.isNull {
            return 0
        }
        
        let intersectionArea = intersection.width * intersection.height
        let rect1Area = self.width * self.height
        let rect2Area = rect2.width * rect2.height
        
        let minArea = min(rect1Area, rect2Area)
        let ratio = intersectionArea / minArea
        
        return ratio
    }
    
    func distanceBetweenRects(_ rect2: CGRect) -> CGFloat {
        if self.intersects(rect2) {
            return 0
        }
        
        let dx: CGFloat
        if self.maxX < rect2.minX {
            dx = rect2.minX - self.maxX
        } else if rect2.maxX < self.minX {
            dx = self.minX - rect2.maxX
        } else {
            dx = 0
        }
        
        let dy: CGFloat
        if self.maxY < rect2.minY {
            dy = rect2.minY - self.maxY
        } else if rect2.maxY < self.minY {
            dy = self.minY - rect2.maxY
        } else {
            dy = 0
        }
        
        return sqrt(dx * dx + dy * dy)
    }
}
//
//extension CameraCoordinator {
//
//}
