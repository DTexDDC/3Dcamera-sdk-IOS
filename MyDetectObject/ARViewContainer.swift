import SwiftUI
import AVFoundation
import TensorFlowLiteTaskVision
import Vision
import CoreImage
import ARKit
import SceneKit
import Accelerate
import CoreVideo

struct ARViewContainer: UIViewRepresentable, DetectDelegate {
    public var arView = ARSCNView()
    @EnvironmentObject var objectDetectionHelper: ObjectDetectionHelper
    @Binding var objectDetect: [ObjectDetect]
    @Binding var showCamera: Bool
    @Binding var showMovementWarning: Bool
    
    func makeUIView(context: Context) -> ARSCNView {
//        let discoverySession = AVCaptureDevice.DiscoverySession(
//            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
//            mediaType: .video,
//            position: .back
//        )
//        let availableDevices = discoverySession.devices
//        let selectedDevice = availableDevices.first(where: { $0.deviceType == .builtInUltraWideCamera })
        
        arView.delegate = context.coordinator
        
        var coo = context.coordinator
        coo.sceneView = arView
        coo.delegate = self
        arView.session.delegate = coo
        
//        for videoFormat in ARPositionalTrackingConfiguration.supportedVideoFormats{
//            if videoFormat.captureDeviceType == .builtInUltraWideCamera {
//                print("Can use Ultra Wide")
//            } else {print("Can't use Ultra Wide")}
//        }

        let configuration = ARWorldTrackingConfiguration()// Maybe Replace with SpatialTrackingSession
        arView.translatesAutoresizingMaskIntoConstraints = false
        arView.contentMode = .scaleAspectFill
        arView.contentScaleFactor = 4.0
        arView.preferredFramesPerSecond = 30
        arView.automaticallyUpdatesLighting = true
        arView.rendersCameraGrain = true
        
        configuration.isAutoFocusEnabled = true
        guard let hiResFormat = ARWorldTrackingConfiguration.recommendedVideoFormatFor4KResolution else {
            fatalError("4K video format not supported.")}
//        for videoFormat in ARPositionalTrackingConfiguration.supportedVideoFormats {
//            if videoFormat.captureDeviceType == .builtInUltraWideCamera {
//                configuration.videoFormat = videoFormat
//                print("Using Ultra Wide")
//                break
//            }
//        }
        configuration.videoFormat = hiResFormat
        configuration.videoHDRAllowed = true
        configuration.worldAlignment = .gravity //This might be causing the shifts in the AR bounding boxes.
//        configuration.environmentTexturing = .none
//        if let videoFormat = ARWorldTrackingConfiguration.supportedVideoFormats.first(where: { $0.captureDeviceType == .builtInUltraWideCamera }) {
//                    configuration.videoFormat = videoFormat
//                } else {
//                    print("Ultra-wide camera not available. Using default.")
//                }
//        if let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
//            print("Ultra-wide camera is available.")
//        } else {
//            print("Ultra-wide camera is not available on this device.")
//        }
        configuration.planeDetection = [.vertical]
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
//        print("makeCoordinator")
        objectDetectionHelper.setup()
        return Coordinator(objectDetectionHelper: objectDetectionHelper, showCamera: $showCamera, showMovementWarning: $showMovementWarning) // ARKit UI updates update SwiftUI, and reference to Helper.
    }
    
    func didUpdateBoundingBoxes(_ detectedObjects: [ObjectDetect]) { // Updates objectDetect when new detections occur.
//        DispatchQueue.main.async {
//            
//        }
        if (detectedObjects.isEmpty) {
            self.objectDetect.removeAll()
        } else if (detectedObjects[0].name == "invalid") {
        } else {
            for item in detectedObjects {
                self.objectDetect.append(item)
            }
        }
    }
    
    func clearobjectDetect() {
        self.objectDetect.removeAll()
    }
    
    func detect(pixelBuffer: CVPixelBuffer) {
        
    }
}


class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
    var sceneView: ARSCNView?
    var objectNode: SCNNode?
    var delegate: DetectDelegate? // Set variables to be used.
    private let edgeOffset: CGFloat = 2.0
    private let labelOffset: CGFloat = 10.0 // Margins for bounding box and label positioning.
    var detectedProducts: [UUID: ObjectDetectionProduct] = [:] // Track detected products with a unique ID.
    struct TrackedBox {
        var id: Int
        var boundingBox: CGRect
    }
    
    var frameCount = 0.0
    var displayLink: CADisplayLink?
            
//    var trackedBoxes: [TrackedBox] = []
    var nextID = 0
    var objectDetectionHelper: ObjectDetectionHelper
    private var isInferenceQueueBusy = false
    private let inferenceQueue = DispatchQueue(label: "org.tensorflow.lite.inferencequeue") // Inference queue for TFL managed using background queue.
//    private var inferenceQueue = OperationQueue()
//    inferenceQueue.maxConcurrentOperationCount = 1
    
    private let imageProcessingQueue = DispatchQueue(label: "com.processing.imageprocessingqueue", qos: .userInitiated)
    
    @Binding var showMovementWarning: Bool
    private var lastCameraPos: simd_float3?
    private var movementThreshold: Float = 0.025 //Maybe change to 0.005.
    private var isStable: Bool = true
    private var countDown: Int = 10000 // Maybe change to 30000.
    @Binding var showCamera: Bool
    let scaledSize = CGSize(width: CGFloat(640), height: CGFloat(640))
    
    init(objectDetectionHelper: ObjectDetectionHelper, showCamera: Binding<Bool>, showMovementWarning: Binding<Bool>) {
        self.objectDetectionHelper = objectDetectionHelper
        _showCamera = showCamera
        _showMovementWarning = showMovementWarning
    }
    
//    func setupDisplayLink() {
//        // Create a CADisplayLink instance
//        displayLink = CADisplayLink(target: self, selector: #selector(updateFrameCount))
//        
//        // Start the display link
//        displayLink?.add(to: .current, forMode: .common)
//    }
//    @objc func updateFrameCount() {
//        // Increment the frame count each time the display link fires
//        frameCount += 1
//    }
    
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        
//        if let planeAnchor = anchor as? ARPlaneAnchor  {
//            
//            // Create a plane to visualize the anchor
//            let planeNode = createPlaneNode(for: planeAnchor)
//            node.addChildNode(planeNode)
//            print("works fine")
//            // Lock the plane once detected
//            lockPlane(anchor: planeAnchor, node: node)
//        } else { return }
//        }
//
//        func createPlaneNode(for planeAnchor: ARPlaneAnchor) -> SCNNode {
//            let width = CGFloat(planeAnchor.planeExtent.width)
//            let height = CGFloat(planeAnchor.planeExtent.height)
//            
//            let planeGeometry = SCNPlane(width: width, height: height)
//            planeGeometry.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.3)
//            
//            let planeNode = SCNNode(geometry: planeGeometry)
//            planeNode.eulerAngles.x = -.pi / 2 // Rotate to lie flat
//            return planeNode
//        }
//
//        func lockPlane(anchor: ARPlaneAnchor, node: SCNNode) {
//            // Freeze the node's position
//            node.simdTransform = anchor.transform
//            
//            // Optionally remove ARKit plane updates to keep the plane static
//            let newConfiguration = ARWorldTrackingConfiguration()
//            newConfiguration.planeDetection = [] // Disable plane detection
//            sceneView?.session.run(newConfiguration, options: [.resetTracking, .removeExistingAnchors])
//        }
//    
    // THIS IS NOT USED.
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) { // At an anchor position adds a sphere.
//        print("renderer")
//        if let anchor = anchor as? ARPlaneAnchor { // **No plane anchor. Just normal
//            print("yes")
//            let sphere = SCNSphere(radius: 0.05) // **Create a bounding box instead https://stackoverflow.com/questions/51552293/show-bounding-box-while-detecting-object-using-arkit-2
//            // **Create either that bounding box OR a plane object with wireframe edges and not filled in at the centre.
//            let material = SCNMaterial()
//            material.diffuse.contents = UIColor.red
//            sphere.materials = [material]
//            
//            let node = SCNNode(geometry: sphere)
//            node.position = SCNVector3(anchor.center.x, anchor.center.y, anchor.center.z)
//            self.sceneView?.scene.rootNode.addChildNode(node)
//            self.objectNode = node
//        }
//        if let planeAnchor = anchor as? ARPlaneAnchor {
////                let planeNode = createPlaneNode(for: planeAnchor)
////                node.addChildNode(planeNode)
//            self.addPlane
//            }
//    }
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        if let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes.first,
//           let planeGeometry = planeNode.geometry as? SCNPlane {
//            planeGeometry.width = CGFloat(planeAnchor.geometry.dimensions.x)
//            planeGeometry.height = CGFloat(planeAnchor.extent.z)
//            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
//        }
//    }
//    func createPlaneNode(for anchor: ARPlaneAnchor) -> SCNNode {
//        let planeGeometry = SCNPlane(width: CGFloat(anchor.geometry.dimensions.x), height: CGFloat(anchor.geometry.dimensions.z))
//        planeGeometry.materials.first?.diffuse.contents = UIColor.blue.withAlphaComponent(0.5)
//        let planeNode = SCNNode(geometry: planeGeometry)
//        planeNode.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
//        planeNode.eulerAngles.x = -.pi / 2
//        return planeNode
//    }
    
    func clearProducts() {
        if let firs = objectDetectionHelper.detectedProducts.first?.name{} else {
            sceneView?.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
            delegate?.didUpdateBoundingBoxes([])
            //Remove All Nodes
            
            //Reset the AR Session
//            let configuration = ARWorldTrackingConfiguration()
//            configuration.planeDetection = [] // Adjust as needed
//            sceneView?.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) { // Capture frames from the AR session.
        // **Add code that limits to 3 times a second so every 20 frames. Since this is 60fps.
//        setupDisplayLink()
//        print(showCamera)
//        print("ShowCamera", showCamera)
        if (!showCamera) {
            clearProducts()	
        } else {
            scanObjectFromCamera(session, frame: frame)
            //        didOutput(session, frame: frame)
            clearProducts()
        }
    }
    
    func cameraMovement(currentFrame: ARFrame) {
        let currentCameraPos = simd_float3(currentFrame.camera.transform.columns.3.x,
                                           currentFrame.camera.transform.columns.3.y,
                                           currentFrame.camera.transform.columns.3.z)
        
        
        if let lastPos = lastCameraPos{
            let movement = simd_distance(currentCameraPos, lastPos)
//            print(movement)
            DispatchQueue.main.async {
                self.$showMovementWarning.wrappedValue = movement > self.movementThreshold || (self.countDown > 0 && !self.isStable)
            }
            
            if movement < movementThreshold || !isStable {
                if (countDown > 0 && !isStable) {
                    isStable = false
                    countDown -= 1000
                } else {
                    isStable = true
                }
            } else {
                countDown = 20000
                isStable = false
            }
        } else {
            print("System Error: No last camera position")
        }
        lastCameraPos = currentCameraPos
        
    }

    func scanObjectFromCamera(_ session: ARSession, frame: ARFrame) { // Convert AR scene/frame to an image type where objects can be scanned by TFL.
//            print("scanObjectFromCamera")
//        print(showCamera)
        if isInferenceQueueBusy { return }
        cameraMovement(currentFrame: frame)
        if (!isStable) {return}
        
        var capturedImagePixelBuffer: CVPixelBuffer? = frame.capturedImage
        guard let shrunkBuffer = convertYUVToBGRA(pixelBuffer: capturedImagePixelBuffer!) else { return }
        let cameraPosition = frame.camera.transform
//        inferenceQueue.async {
        imageProcessingQueue.async {
            self.isInferenceQueueBusy = true
            let startDate = Date()
            //            Run the TFL detection on the object.
            //            let interval = Date().timeIntervalSince(startDate) * 1000 // Set the time for when the TFL detection inference was completed.
            //            // inference
            //            print(interval)
            //        inferenceQueue.async {
//            guard let frame = session.currentFrame else { return }
//            var capturedImagePixelBuffer: CVPixelBuffer? = frame.capturedImage
//            let cameraPosition = frame.camera.transform
//            guard let shrunkBuffer = self.convertYUVToBGRA(pixelBuffer: capturedImagePixelBuffer!) else { return }
            guard let result1 = self.pixelBufferShrink(shrunkBuffer)
            else { return }
//            guard let newImage = result1.resized(to: self.scaledSize)
//            else { return }
            guard let result2 = self.rotatePixelBuffer(pixelBuffer: result1, rotation: 90) else { return }
            //            guard let pixelBufferPadded = self.pixelBufferAddPadding(pb: result2, padding: 400) else { return }
            //            guard let result3 = self.pixelBufferShrink(pb: result2) else { return }
            
            //            return result3
            //            if let cgImage = pixelBufferToUIImage(session) {
            //                if let i = ImageProcessor.pixelBuffer(forImage: cgImage) {
            //            let ciImageDepth  = CIImage(cvPixelBuffer: result2)
            //                    let contextDepth:CIContext  = CIContext.init(options: nil)
            //                    let cgImageDepth:CGImage    = contextDepth.createCGImage(ciImageDepth, from: ciImageDepth.extent)!
            //                    let uiImageDepth:UIImage    = UIImage(cgImage: cgImageDepth, scale: 1, orientation: UIImage.Orientation.up)
            //
            //                    // Save UIImage to Photos Album
            //                    UIImageWriteToSavedPhotosAlbum(uiImageDepth, nil, nil, nil)
            let interval = Date().timeIntervalSince(startDate) * 1000 // Set the time for when the TFL detection inference was completed.
            // inference
//            print(interval)
            self.didOutput(session: session, imageToAnalyse: result2, cameraPosition: cameraPosition)
//            capturedImagePixelBuffer = nil
            //                }
            //            }
        }
    }
    
    func convertYUVToBGRA(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        let context = CIContext(options: nil)

        var bgraPixelBuffer: CVPixelBuffer?
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        let attributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferBytesPerRowAlignmentKey: width * 4
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &bgraPixelBuffer
        )

        guard status == kCVReturnSuccess, let outputBuffer = bgraPixelBuffer else {
            print("Error creating BGRA pixel buffer")
            return nil
        }

        context.render(ciImage, to: outputBuffer)

        return outputBuffer
    }
    
    func convertBGRAtoRGB(_ pixelBuffer: CVPixelBuffer) -> Data? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let sourceBaseAddr = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        var bgraBuffer = vImage_Buffer(data: sourceBaseAddr, height: vImagePixelCount(height),
                                       width: vImagePixelCount(width), rowBytes: bytesPerRow)

        let rgbData = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 3)
        defer { rgbData.deallocate() }
        
        var rgbBuffer = vImage_Buffer(data: rgbData, height: vImagePixelCount(height),
                                      width: vImagePixelCount(width), rowBytes: width * 3)
        
        let map: [UInt8] = [2, 1, 0] // Reorder BGRA → RGB
        vImagePermuteChannels_ARGB8888(&bgraBuffer, &rgbBuffer, map, vImage_Flags(kvImageNoFlags))

        return Data(bytes: rgbBuffer.data, count: width * height * 3)
    }
    
    func pixelBufferShrink(_ pb: CVPixelBuffer) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: pb)

            // Create a Core Image context
            let context = CIContext()

            // Create a new CVPixelBuffer for the resized image
            var resizedPixelBuffer: CVPixelBuffer?
            let pixelFormat = CVPixelBufferGetPixelFormatType(pb)
            let attributes: [CFString: Any] = [
                kCVPixelBufferCGImageCompatibilityKey: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true
            ]

            let status = CVPixelBufferCreate(
                kCFAllocatorDefault,
                640,
                640,
                pixelFormat,
                attributes as CFDictionary,
                &resizedPixelBuffer
            )

            guard status == kCVReturnSuccess, let outputBuffer = resizedPixelBuffer else {
                print("Failed to create resized CVPixelBuffer.")
                return nil
            }

            // Scale the CIImage
            let scaleX = CGFloat(640) / CGFloat(CVPixelBufferGetWidth(pb))
            let scaleY = CGFloat(640) / CGFloat(CVPixelBufferGetHeight(pb))
            let scaledCIImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

            // Render the scaled CIImage to the new CVPixelBuffer
            CVPixelBufferLockBaseAddress(outputBuffer, [])
            context.render(scaledCIImage, to: outputBuffer)
            CVPixelBufferUnlockBaseAddress(outputBuffer, [])

            return outputBuffer
    }
    
    func pixelBufferAddPadding(pb: CVPixelBuffer, padding: Int) -> CVPixelBuffer? {
        let originalWidth = CVPixelBufferGetWidth(pb)
        let originalHeight = CVPixelBufferGetHeight(pb)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pb)
        
        let paddedWidth = originalWidth + padding
        let paddedHeight = originalHeight
        
        // Create a new CVPixelBuffer with padded dimensions
            var paddedPixelBuffer: CVPixelBuffer?
            let attributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
                kCVPixelBufferWidthKey as String: paddedWidth,
                kCVPixelBufferHeightKey as String: paddedHeight,
                kCVPixelBufferIOSurfacePropertiesKey as String: [:] // Required for Metal compatibility
            ]
            let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                             paddedWidth,
                                             paddedHeight,
                                             pixelFormat,
                                             attributes as CFDictionary,
                                             &paddedPixelBuffer)
            guard status == kCVReturnSuccess, let newBuffer = paddedPixelBuffer else {
                print("Failed to create padded pixel buffer.")
                return nil
            }
        
        // Lock both pixel buffers for accessing their base addresses
           CVPixelBufferLockBaseAddress(pb, .readOnly)
           CVPixelBufferLockBaseAddress(newBuffer, [])

           // Get base addresses and bytes per row
           guard let sourceBaseAddress = CVPixelBufferGetBaseAddress(pb),
                 let destBaseAddress = CVPixelBufferGetBaseAddress(newBuffer) else {
               print("Failed to get base addresses.")
               CVPixelBufferUnlockBaseAddress(pb, .readOnly)
               CVPixelBufferUnlockBaseAddress(newBuffer, [])
               return nil
           }

           let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(pb)
           let destBytesPerRow = CVPixelBufferGetBytesPerRow(newBuffer)

           // Copy the original image to the center of the new buffer
           for row in 0..<originalHeight {
               let sourceRowPointer = sourceBaseAddress + row * sourceBytesPerRow
               let destRowPointer = destBaseAddress + row * destBytesPerRow + padding * 4 // Assuming 4 bytes per pixel (e.g., BGRA)
               memcpy(destRowPointer, sourceRowPointer, sourceBytesPerRow)
           }

           // Unlock pixel buffers
           CVPixelBufferUnlockBaseAddress(pb, .readOnly)
           CVPixelBufferUnlockBaseAddress(newBuffer, [])
        
//        let ciImageDepth  = CIImage(cvPixelBuffer: newBuffer)
//        let contextDepth:CIContext  = CIContext.init(options: nil)
//        let cgImageDepth:CGImage    = contextDepth.createCGImage(ciImageDepth, from: ciImageDepth.extent)!
//        let uiImageDepth:UIImage    = UIImage(cgImage: cgImageDepth, scale: 1, orientation: UIImage.Orientation.up)
//
//        // Save UIImage to Photos Album
//        UIImageWriteToSavedPhotosAlbum(uiImageDepth, nil, nil, nil)
        
            return newBuffer
    }
    
    func pixelBufferSegment(pb: CVPixelBuffer) {
        
    }
    
    
    func pixelBufferToUIImage(_ session: ARSession) -> CGImage? { // Convert the TFL image to a UI Image that can be outputted to the screen.
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let overlayView = self.sceneView else { return nil }
        let context = CIContext()
        if let ciImage = session.resizeTo(overlayView) {
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
//                objectDetectionHelper.imagePreview = UIImage(cgImage: cgImage)
                return cgImage
            }
        }
        return nil

//        objectDetectionHelper.imagePreview = resizeTo(CGSize(width:300,height:300))
    }
    
    func pixelBufferNormalise(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Normalize pixel values to [0, 1] by dividing by 255
        var normalizedImage = ciImage.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1/255, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1/255, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1/255, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])
        
        var context = CIContext()
        var normalizedPixelBuffer: CVPixelBuffer?
        var attrs = [kCVPixelBufferCGImageCompatibilityKey: true,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary
        
        CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                            kCVPixelFormatType_32BGRA, attrs,
                            &normalizedPixelBuffer)
        
        if let normalizedPixelBuffer = normalizedPixelBuffer {
            context.render(normalizedImage, to: normalizedPixelBuffer)
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        return normalizedPixelBuffer
    }
    
    func didOutput(session: ARSession, imageToAnalyse: CVPixelBuffer, cameraPosition: simd_float4x4) { // Enqueue object detection tasks.
//            guard !self.isInferenceQueueBusy else { return }
//        let newImage = self.pixelBufferNormalise(shrunkImage!)
//                self.isInferenceQueueBusy = true
//                let cameraPosition = frame.camera.transform
//                let imageToAnalyse = self.scanObjectFromCamera(session, frame: frame)
//                if imageToAnalyse == nil {
//                    self.isInferenceQueueBusy = false
//                    return
//                } else {
//        DispatchQueue.global(qos: .userInitiated).async {
//        if isInferenceQueueBusy { return }
//
////        inferenceQueue.async {
//            self.isInferenceQueueBusy = true
        self.detect(session: session, pixelBuffer: imageToAnalyse, cameraPosition: cameraPosition)
            //                    self.isInferenceQueueBusy = false
//        }
    }
    
    func detect(session: ARSession, pixelBuffer: CVPixelBuffer, cameraPosition: simd_float4x4) { // Run the detection analysis and get the appropriate information.
//        var c = ObjectDetectionHelper()
//        c.setup()
        let result = objectDetectionHelper.detect(pixelBuffer: pixelBuffer)
//        if result?.detections.count == 0 { return }
//            guard let displayResult = result else {
//                //          print("displayResult null")
//                return
//            }
//        print(result?.count)
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)

        if (result?.count == nil) {
            self.isInferenceQueueBusy = false
            return
        }
                
                //        var inferenceTime: Double = 0
                //        if let resultInferenceTime = result?.inferenceTime {
                //          inferenceTime = resultInferenceTime
                //        }
                
                //          print(displayResult.detections.count)
                
                
                // Draws the bounding boxes and displays class names and confidence scores.
//        DispatchQueue.main.async {
        DispatchQueue.main.async {
            self.addUniqueBoxes(session: session,
                detections: result!,
                imageSize: CGSize(width: CGFloat(width), height: CGFloat(height)),
                cameraPosition: cameraPosition
            )
        }
        self.isInferenceQueueBusy = false
//        print("Processing")
    }
    
    func addUniqueBoxes(session: ARSession, detections: [ObjectDetect], imageSize: CGSize, cameraPosition: simd_float4x4){
        guard let currentFrame = session.currentFrame else { return }
        var boxs: [ObjectDetect] = []
        // **Compare the result detected object coordinates with the already present detected object coordinates to see if there are any new objects.
        // **Use projectPoint to get the position of a node object. The x, y values are 2D screen coordinates.
        // **If there are new objects, then execute everything below.
        
        guard let overlayView = self.sceneView else { return }
//        print(overlayView.bounds.width, overlayView.bounds.height)
//        DispatchQueue.main.async {
//        print(detections.count)
            for detection in detections {
                print("Adding", detection)
                //            guard let category = detection.categories.first else { continue }
                //
                //            let convertedRect = detection.boundingBox.applying( // Scale detection bounding box to fit the AR scene.
                //                CGAffineTransform(
                //                    scaleX: overlayView.bounds.size.width / imageSize.width,
                //                    y: overlayView.bounds.size.height / imageSize.height))
                //
                ////            print("\(overlayView.bounds.size.width) \(overlayView.bounds.size.height) | \(imageSize.width) \(imageSize.height) | \(detection.boundingBox.width) \(detection.boundingBox.height) | \(detection.boundingBox.origin.x) \(detection.boundingBox.origin.y) ")
                //            let screenPoint = CGPoint( // Finds rectangle midpoint.
                //                x: convertedRect.midX,
                //                y: convertedRect.midY
                //            )
                
                var left = detection.left * Float(overlayView.bounds.size.width/640)
                var top = detection.top * Float(overlayView.bounds.size.height/640)
                var right = detection.right * Float(overlayView.bounds.size.width/640)
                var bottom = detection.bottom * Float(overlayView.bounds.size.height/640)
//                var width = CGFloat(right-left)
//                var height = CGFloat(bottom-top)
//                let adjustedWidth = Float(width/2)
//                let adjustedHeight = Float(height/2)
                
                let boundingBox = CGRect(x: Int(detection.left), y: Int(detection.top), width: Int(detection.w), height: Int(detection.h))
                var convertedRect = boundingBox.applying( // Scale detection bounding box to fit the AR scene.
                    CGAffineTransform(
                        scaleX: overlayView.bounds.size.width / 640,
                        y: overlayView.bounds.size.height / 640))
//                print(convertedRect)
                let screenPoint = CGPoint( // Finds rectangle midpoint.
                    x: convertedRect.midX,
                    y: convertedRect.midY
                )
                
//                let leftPoint = CGPoint(x: CGFloat(left), y: CGFloat(top+adjustedHeight))
//                let rightPoint = CGPoint(x: CGFloat(right), y: CGFloat(top+adjustedHeight))
//                let topPoint = CGPoint(x: CGFloat(left+adjustedWidth), y: CGFloat(top))
//                let bottomPoint = CGPoint(x: CGFloat(left+adjustedWidth), y: CGFloat(bottom))
        
                if let worldPosition = overlayView.worldPosition(from: screenPoint) {
                    var check = true
//                    guard let leftWorld = overlayView.worldPosition(from: leftPoint),
//                          let rightWorld = overlayView.worldPosition(from: rightPoint),
//                          let topWorld = overlayView.worldPosition(from: topPoint)  else {
//                            return
//                        }
//                                    print(screenPoint, worldPosition)
                    
                    
                    let width: CGFloat = convertedRect.width
                    let height: CGFloat = convertedRect.height
                    
                    let cameraPosition1 = cameraPosition.columns.3
                    let distance = simd_length(cameraPosition1 - simd_float4(x: worldPosition.x, y: worldPosition.y, z: worldPosition.z, w: 1.0))
                    let baseScale: CGFloat = 0.00012
                    let scale: CGFloat = CGFloat(distance) * baseScale / 0.08
                    
                    let adjustedWidth = width * scale
                    let adjustedHeight = height * scale
                    let min = SCNVector3(x: worldPosition.x - Float(adjustedWidth)/2,
                                         y: worldPosition.y - Float(adjustedHeight)/2,
                                         z: worldPosition.z)

                    let max = SCNVector3(x: worldPosition.x + Float(adjustedWidth)/2,
                                         y: worldPosition.y + Float(adjustedHeight)/2,
                                         z: worldPosition.z)
                    //                let distance = simd_length(cameraPosition1 - simd_float4(x: worldPosition.x, y: worldPosition.y, z: worldPosition.z, w: 1.0))
                    //
                    //                let baseScale: CGFloat = 0.00012
                    //                let scale: CGFloat = CGFloat(distance) * baseScale / 0.08
                    //
                    //                let adjustedWidthEndtoEnd = width * scale
                    //                let adjustedHeightEndtoEnd = height * scale
                    
                    
                    //        print("truc z \(worldPosition.z)")
//                    let min = SCNVector3(x: leftWorld.x,
//                                         y: topWorld.y,
//                                         z: topWorld.z)
//                    
//                    let max = SCNVector3(x: rightWorld.x,
//                                         y: bottomWorld.y,
//                                         z: bottomWorld.z)
//                    
//                    let worldWidth = simd_distance(simd_float3(leftWorld), simd_float3(rightWorld))
//                    let worldHeight = simd_distance(simd_float3(topWorld), simd_float3(bottomWorld))
//                    
                    let cx = Float(worldPosition.x)
                    let cy = Float(worldPosition.y)
//
//                    print(worldPosition)
//                    print(left, top, right, bottom, width, height, detection.conf)
                    let calcWidth = Float(adjustedWidth)/4
                    let calcHeight = Float(adjustedHeight)/4
                    let detectedProducts = self.objectDetectionHelper.detectedProducts
//                    check = true
                    if (detectedProducts.isEmpty) {
                        check = true
                    } else {
                        for product in detectedProducts {
                            let worldBoundingBox = product.worldPositionBox
                            var isInside = false
                            if (detection.name == "shelf") {
                                if (product.name == "shelf") {
                                    isInside = calculateIOU(box1: product, minimum: min, maximum: max) >= 0.1
                                }
                            } else if (detection.name == "end_point") {
                                if (detection.name == "end_point") {
                                    isInside = calculateIOU(box1: product, minimum: min, maximum: max) >= 0.1
                                }
                            } else {
                                isInside = calculateIOU(box1: product, minimum: min, maximum: max) >= 0.1
                            }
                            print(isInside)
//                            let isInside = false
//                            let isInside = cx < worldBoundingBox.max.x && cx > worldBoundingBox.min.x && cy < worldBoundingBox.max.y && cy > worldBoundingBox.min.y
//                            print(isInside, cx, cy, worldBoundingBox.max.x, worldBoundingBox.min.x, worldBoundingBox.max.y, worldBoundingBox.min.y)
//                            || cx+calcWidth < worldBoundingBox.max.x && cx+calcWidth > worldBoundingBox.min.x && cy < worldBoundingBox.max.y && cy > worldBoundingBox.min.y || cx < worldBoundingBox.max.x && cx > worldBoundingBox.min.x && cy+calcWidth < worldBoundingBox.max.y && cy+calcWidth > worldBoundingBox.min.y || cx-calcWidth < worldBoundingBox.max.x && cx-calcWidth > worldBoundingBox.min.x && cy < worldBoundingBox.max.y && cy > worldBoundingBox.min.y || cx < worldBoundingBox.max.x && cx > worldBoundingBox.min.x && cy-calcWidth < worldBoundingBox.max.y && cy-calcWidth > worldBoundingBox.min.y
                            
                            /*(min.x >= worldBoundingBox.min.x && min.x <= worldBoundingBox.max.x && max.y >= worldBoundingBox.min.y && max.y <= worldBoundingBox.max.y) || (min.x >= worldBoundingBox.min.x && min.x <= worldBoundingBox.max.x && min.y >= worldBoundingBox.min.y && min.y <= worldBoundingBox.max.y) || (max.x >= worldBoundingBox.min.x && max.x <= worldBoundingBox.max.x && max.y >= worldBoundingBox.min.y && max.y <= worldBoundingBox.max.y) || (max.x >= worldBoundingBox.min.x && max.x <= worldBoundingBox.max.x && min.y >= worldBoundingBox.min.y && min.y <= worldBoundingBox.max.y) || ((min.x+max.x)/2 >= worldBoundingBox.min.x && (min.x+max.x)/2 <= worldBoundingBox.max.x && (min.y+max.y)/2 >= worldBoundingBox.min.y && (min.y+max.y)/2 <= worldBoundingBox.max.y)*/
                            
                            if isInside {
                                check = false
                                break
                            }
                            check = true
                            //                    print(isInside)
                        }
                    }
                    if (check) {
//                        print("passed")
                        let currentCameraPos = simd_float3(currentFrame.camera.transform.columns.3.x,
                                                           currentFrame.camera.transform.columns.3.y,
                                                           currentFrame.camera.transform.columns.3.z)
                        if let lastPos = self.lastCameraPos{
                            let movement = simd_distance(currentCameraPos, lastPos)
                            if movement > movementThreshold {
                                break
                            } else {
                                let id: Int
                                id = self.nextID
                                self.nextID += 1
                                
                                let objectDescription = String(format: "\(detection.name) (%.2f)", detection.conf) // Create a string representation of the object.
                                detection.label = "\(objectDescription) - ID \(id)"
                                detection.worldPositionBox = BoundingBox3D(min: min, max: max)
                                detection.left = left
                                detection.right = right
                                detection.top = top
                                detection.bottom = bottom
                                detection.w = Float(width)
                                detection.h = Float(height)
                                detection.boundingBoxes = convertedRect
//                                print(convertedRect)
//                                print(detection.worldPositionBox)
                                // Create an ObjectDetect item and append it to boxs.
                                boxs.append(detection)
//                                print(detection.worldPositionBox.max.x, detection.worldPositionBox.max.y, detection.worldPositionBox.min.x, detection.worldPositionBox.min.y)
                        if (!showCamera) {
                            return
                        }
                                self.objectDetectionHelper.detectedProducts.append(detection)
//                                print("Adding \(detection.worldPositionBox)")

                        self.drawRectangleInAR(rectangleBoundingBox: detection.worldPositionBox, worldPosition: worldPosition, worldWidth: adjustedWidth, worldHeight: adjustedHeight, label: detection.label, name: detection.name)
                            }
                        }
                    }
                    
                    //                print("drawAfterPerformingCalculations")
                    //            self.trackProduct(label: objectDescription, position: worldPosition, convertedRect: convertedRect, objectDetect: item, cameraPosition: cameraPosition, frame: frame)
                }
            }
            
            
            //        trackedBoxes = newTrackedBoxes // Update trackedBoxes list for next detection cycle.
            if boxs.isEmpty { //fix this so that you change the name to "invalid", and then check for this in didUpdateBB
                let emptyItem = ObjectDetect()
                emptyItem.name = "invalid"
                boxs.append(emptyItem)
            }
            self.delegate?.didUpdateBoundingBoxes(boxs) // Notifies delegate about the updated bounding boxes.
//        }
    }
    
    private func calculateIOU(box1: ObjectDetect, minimum: SCNVector3, maximum: SCNVector3) -> Float {
        var x1 = max(box1.worldPositionBox.min.x, minimum.x)
        var y1 = max(box1.worldPositionBox.min.y, minimum.y)
        var x2 = min(box1.worldPositionBox.max.x, maximum.x)
        var y2 = min(box1.worldPositionBox.max.y, maximum.y)
        
        var intersectionArea = max(Float(0), x2-x1) * max(Float(0), y2-y1)
        var box1Area = (box1.worldPositionBox.max.x-box1.worldPositionBox.min.x) *
        (box1.worldPositionBox.max.y - box1.worldPositionBox.min.y)
        var box2Area = (maximum.x - minimum.x) * (maximum.y - minimum.y)
        
        return intersectionArea / (box1Area + box2Area - intersectionArea)
    }
    
    func rotatePixelBuffer(pixelBuffer: CVPixelBuffer, rotation: Int) -> CVPixelBuffer? { // Rotates the image data as needed.
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        guard pixelFormat == kCVPixelFormatType_32BGRA else {
            print("Error: Unsupported pixel format \(pixelFormat). Expected BGRA.")
            return nil
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        let rotatedWidth = (rotation == 90 || rotation == 270) ? height : width
        let rotatedHeight = (rotation == 90 || rotation == 270) ? width : height

        let attributes: [String: Any] = [ // New pixelBuffer for the rotated image defined.
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: rotatedWidth,
            kCVPixelBufferHeightKey as String: rotatedHeight,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]

        var rotatedBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            rotatedWidth,
            rotatedHeight,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &rotatedBuffer
        )
        
        guard status == kCVReturnSuccess, let outputBuffer = rotatedBuffer else { // Verify that the new buffer has been created successfully.
            print("Error: Unable to create rotated pixelBuffer")
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(outputBuffer, [])
        
        guard let sourceBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer),
              let destinationBaseAddress = CVPixelBufferGetBaseAddress(outputBuffer) else {
            print("Error: Unable to access base address of buffers")
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(outputBuffer, [])
            return nil
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let sourceData = sourceBaseAddress.assumingMemoryBound(to: UInt8.self)
        let destinationData = destinationBaseAddress.assumingMemoryBound(to: UInt8.self)

        let destinationBytesPerRow = CVPixelBufferGetBytesPerRow(outputBuffer)
        
        for y in 0..<height {
            for x in 0..<width {
                let sourceOffset = y * bytesPerRow + x * 4
                
                var destX = 0
                var destY = 0

                switch rotation {
                case 90:
                    destX = height - 1 - y
                    destY = x
                case 180:
                    destX = width - 1 - x
                    destY = height - 1 - y
                case 270:
                    destX = y
                    destY = width - 1 - x
                default:
                    destX = x
                    destY = y
                }
                
                let destinationOffset = destY * destinationBytesPerRow + destX * 4
                
                destinationData[destinationOffset] = sourceData[sourceOffset]         // Blue
                destinationData[destinationOffset + 1] = sourceData[sourceOffset + 1] // Green
                destinationData[destinationOffset + 2] = sourceData[sourceOffset + 2] // Red
                destinationData[destinationOffset + 3] = sourceData[sourceOffset + 3] // Alpha
            } // Basically goes through pixel by pixel and moves the pixels to create a whole rotated image.
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        CVPixelBufferUnlockBaseAddress(outputBuffer, [])
        
//        let ciImageDepth  = CIImage(cvPixelBuffer: outputBuffer)
//                let contextDepth:CIContext  = CIContext.init(options: nil)
//                let cgImageDepth:CGImage    = contextDepth.createCGImage(ciImageDepth, from: ciImageDepth.extent)!
//                let uiImageDepth:UIImage    = UIImage(cgImage: cgImageDepth, scale: 1, orientation: UIImage.Orientation.up)
//        
//                // Save UIImage to Photos Album
//                UIImageWriteToSavedPhotosAlbum(uiImageDepth, nil, nil, nil)
        
        return outputBuffer
    }
    
    
    
    func convertToBGRA(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? { // Convert to BGRA pixel format.
        // Create a CIImage from the source pixel buffer
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Create a rotation transformation (rotation around the center of the image)
//        let rotationTransform = CGAffineTransform(rotationAngle: 180)
//
//        // Apply the rotation to the CIImage
//        let rotatedImage = ciImage.transformed(by: rotationTransform)
        
        let width = ceil(ciImage.extent.width)
        let height = ceil(ciImage.extent.height)

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(width),
            kCVPixelBufferHeightKey as String: Int(height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        
        var bgraBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(width),
            Int(height),
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &bgraBuffer
        )
        
        guard status == kCVReturnSuccess, let outputBuffer = bgraBuffer else {
            print("Error: Không thể tạo BGRA pixelBuffer")
            return nil
        }
            
            // Create a CIContext and render the rotated image into the new BGRA pixel buffer
//            print("pb: \(CVPixelBufferGetWidth(outputBuffer))x \(CVPixelBufferGetHeight(outputBuffer))")
//            print("ci: \(Int(rotatedImage.extent.width))x \(Int(rotatedImage.extent.height))")
            let ciContext = CIContext()
            ciContext.render(ciImage, to: outputBuffer)
        CVPixelBufferUnlockBaseAddress(outputBuffer, .readOnly)
        return outputBuffer
    }
    
    func filterOverlappingBoxes(_ boxes: [ObjectDetect]) {
//        var filteredBoxes = boxes
//        
//        for (i, boxA) in boxes.enumerated() { // Compare every pair of boxes. If boxA contains boxB and boxA has a larger area then remove boxB.
//            for (j, boxB) in boxes.enumerated() {
//                if i != j, boxA.boundingBoxes.area > boxB.boundingBoxes.area,
//                   boxA.boundingBoxes.mostlyContains(boxB.boundingBoxes) {
//                    filteredBoxes.removeAll { $0 === boxB }
//                }
//            }
//        }
//        
//        return filteredBoxes
    }

    func drawAfterPerformingCalculations(onDetections detections: [Detection], withImageSize imageSize: CGSize, cameraPosition: simd_float4x4) {
//        print("-------------Start drawAfterPerformingCalculations------------------")
        var newTrackedBoxes: [TrackedBox] = []
        var boxs: [ObjectDetect] = []
        // **Compare the result detected object coordinates with the already present detected object coordinates to see if there are any new objects.
        // **Use projectPoint to get the position of a node object. The x, y values are 2D screen coordinates.
        // **If there are new objects, then execute everything below.

        // **Don't clear all detections. So change the below code so that only the nodes which don't already have anchors and bounding boxes have them added.
        // **So only for new nodes is everything below executed.
//        if (Int(frameCount)%100 == 0) {
//            self.sceneView?.scene.rootNode.enumerateChildNodes { (node, _) in
//                node.removeFromParentNode() // Clear all previous nodes.
//            }
//            print("executed")
//        }
        
        guard let overlayView = self.sceneView else { return }
        
        for detection in detections {
            guard let category = detection.categories.first else { continue }

            var convertedRect = detection.boundingBox.applying( // Scale detection bounding box to fit the AR scene.
                CGAffineTransform(
                    scaleX: overlayView.bounds.size.width / imageSize.width,
                    y: overlayView.bounds.size.height / imageSize.height))
            
//            print("\(overlayView.bounds.size.width) \(overlayView.bounds.size.height) | \(imageSize.width) \(imageSize.height) | \(detection.boundingBox.width) \(detection.boundingBox.height) | \(detection.boundingBox.origin.x) \(detection.boundingBox.origin.y) ")


//            convertedRect.origin.x = max(self.edgeOffset, convertedRect.origin.x)
//            convertedRect.origin.y = max(self.edgeOffset, convertedRect.origin.y) // Adjust the bounding box so that it stays within the views edges.
//            convertedRect.size.width = min(overlayView.bounds.maxX - convertedRect.origin.x - self.edgeOffset, convertedRect.size.width)
//            convertedRect.size.height = min(overlayView.bounds.maxY - convertedRect.origin.y - self.edgeOffset, convertedRect.size.height)
            // Get width and height to be within view bounds.

//            let closestTrackedBox = trackedBoxes.min(by: { // Find the nearest tracked bounding box to convertedRect.
//                $0.boundingBox.distance(to: convertedRect) < $1.boundingBox.distance(to: convertedRect)
//            })

            let id: Int
//            if let closestBox = closestTrackedBox, closestBox.boundingBox.distance(to: convertedRect) < 30 { // Set ID of the box.
//                id = closestBox.id
//            } else {
                id = nextID
                nextID += 1
//            }

            newTrackedBoxes.append(TrackedBox(id: id, boundingBox: convertedRect)) // Create new tracked box object.


            let objectDescription = String(format: "\(category.label ?? "Unknown") (%.2f)", category.score) // Create a string representation of the object.
//            var item = ObjectDetect()
//            item.boundingBoxes = convertedRect
//            item.label = "\(objectDescription) - ID \(id)"
//            item.name = "\(category.label ?? "Unknown")"
//            // Create an ObjectDetect item and append it to boxs.
            

            
            let screenPoint = CGPoint( // Finds rectangle midpoint.
                x: convertedRect.midX,
                y: convertedRect.midY
            )
            
            if let worldPosition = overlayView.worldPosition(from: screenPoint) {
//                print("drawAfterPerformingCalculations")
//                print("success")
//                let check = self.trackProduct(label: objectDescription, position: worldPosition, convertedRect: convertedRect, objectDetect: item, cameraPosition: cameraPosition, frame: frame)
//                if (check) {
//                    boxs.append(item)
//                }
//                print("objectDetectionHelper.detectedProducts \(objectDetectionHelper.detectedProducts.count)")
                //Convert from 2D to 3D position. If worldPosition is valid then call trackProduct method on the midpoint.
                
            }
            
        }

//        trackedBoxes = newTrackedBoxes // Update trackedBoxes list for next detection cycle.
//        if boxs.isEmpty {
//            boxs.append(ObjectDetect())
//        }
//        delegate?.didUpdateBoundingBoxes(boxs) // Notifies delegate about the updated bounding boxes.
//        print("-------------End drawAfterPerformingCalculations------------------")
    }
    
    func convertBoundingBox3DToCGRect(boundingBox: BoundingBox3D, sceneView: ARSCNView) -> CGRect? { // Convert 3D bounding box to 2D for drawing.
        let width = CGFloat(boundingBox.max.x - boundingBox.min.x)
        let height = CGFloat(boundingBox.max.y - boundingBox.min.y)
        let x = CGFloat(boundingBox.min.x)
        let y = CGFloat(boundingBox.min.y)
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func drawRectangleInAR(rectangleBoundingBox: BoundingBox3D, worldPosition: SCNVector3, worldWidth: CGFloat, worldHeight: CGFloat, label: String, name: String) { // Draw in AR world based on 2D.
//        cameraMovement(currentFrame: frame)
//        print(isStable)
//        if !isStable {return BoundingBox3D(min: SCNVector3(), max: SCNVector3())}
//        
//            let width: CGFloat = convertedRect.width
//            let height: CGFloat = convertedRect.height
//            
//            let cameraPosition1 = cameraPosition.columns.3
//            let distance = simd_length(cameraPosition1 - simd_float4(x: worldPosition.x, y: worldPosition.y, z: worldPosition.z, w: 1.0))
//            
//            let baseScale: CGFloat = 0.00012
//            let scale: CGFloat = CGFloat(distance) * baseScale / 0.08
//            
//            let adjustedWidthEndtoEnd = width * scale
//            let adjustedHeightEndtoEnd = height * scale
//        
//            let adjustedWidth = adjustedWidthEndtoEnd/2
//            let adjustedHeight = adjustedHeightEndtoEnd/2
//            
//            //        print("truc z \(worldPosition.z)")
//            let min = SCNVector3(x: worldPosition.x - Float(adjustedWidth),
//                                 y: worldPosition.y - Float(adjustedHeight),
//                                 z: worldPosition.z)
//            
//            let max = SCNVector3(x: worldPosition.x + Float(adjustedWidth),
//                                 y: worldPosition.y + Float(adjustedHeight),
//                                 z: worldPosition.z)
//            
//            let centre = SCNVector3(x: (min.x + max.x) / 2,
//                                    y: (min.y + max.y) / 2,
//                                    z: worldPosition.z)
//            
//            guard let scnView = self.sceneView else { return BoundingBox3D(min: SCNVector3(), max: SCNVector3())}
//            for node in scnView.scene.rootNode.childNodes{
//                if let plane = node.geometry as? SCNPlane {
//                    let nodeMin = SCNVector3(
//                        x: node.worldPosition.x-Float(plane.width/2),
//                        y: node.worldPosition.y - Float(plane.height/2),
//                        z: node.worldPosition.z)
//                    
//                    let nodeMax = SCNVector3(
//                        x: node.worldPosition.x + Float(plane.width/2),
//                        y: node.worldPosition.y + Float(plane.height/2),
//                        z: node.worldPosition.z)
//                    
//                    let nodeCentre = SCNVector3( x: (nodeMin.x + nodeMax.x) / 2,
//                                                 y: (nodeMin.y + nodeMax.y) / 2,
//                                                 z: (nodeMin.z + nodeMax.z) / 2)
//                    
//                    //                let isOutside = min.x >= nodeMax.x || max.x <= nodeMin.x ||
//                    //                                min.y >= nodeMax.y || max.y <= nodeMin.y ||
//                    //                                min.z >= nodeMax.z || max.z <= nodeMin.z
//                    
//                    let isInside = (centre.x >= nodeMin.x && centre.x <= nodeMax.x && centre.y >= nodeMin.y && centre.y <= nodeMax.y) || (centre.x+Float(adjustedWidth*0.5) >= nodeMin.x && centre.x+Float(adjustedWidth*0.5) <= nodeMax.x && centre.y >= nodeMin.y && centre.y <= nodeMax.y) || (centre.x-Float(adjustedWidth*0.5) >= nodeMin.x && centre.x-Float(adjustedWidth*0.5) <= nodeMax.x && centre.y >= nodeMin.y && centre.y <= nodeMax.y) || (centre.x >= nodeMin.x && centre.x <= nodeMax.x && centre.y+Float(adjustedHeight*0.5) >= nodeMin.y && centre.y+Float(adjustedHeight*0.5) <= nodeMax.y) || (centre.x >= nodeMin.x && centre.x <= nodeMax.x && centre.y-Float(adjustedHeight*0.5) >= nodeMin.y && centre.y-Float(adjustedHeight*0.5) <= nodeMax.y) || (nodeCentre.x >= min.x && nodeCentre.x <= max.x && nodeCentre.y >= min.y && nodeCentre.y <= max.y) || (centre.x+Float(adjustedWidth*0.5) >= nodeMin.x && centre.x+Float(adjustedWidth*0.5) <= nodeMax.x && centre.y+Float(adjustedHeight*0.5) >= nodeMin.y && centre.y+Float(adjustedHeight*0.5) <= nodeMax.y) || (centre.x+Float(adjustedWidth*0.5) >= nodeMin.x && centre.x+Float(adjustedWidth*0.5) <= nodeMax.x && centre.y-Float(adjustedWidth*0.5) >= nodeMin.y && centre.y-Float(adjustedWidth*0.5) <= nodeMax.y) || (centre.x-Float(adjustedWidth*0.5) >= nodeMin.x && centre.x-Float(adjustedWidth*0.5) <= nodeMax.x && centre.y+Float(adjustedHeight*0.5) >= nodeMin.y && centre.y+Float(adjustedHeight*0.5) <= nodeMax.y) || (centre.x-Float(adjustedWidth*0.5) >= nodeMin.x && centre.x-Float(adjustedWidth*0.5) <= nodeMax.x && centre.y-Float(adjustedHeight*0.5) >= nodeMin.y && centre.y-Float(adjustedHeight*0.5) <= nodeMax.y)
//                    
//                    
//                    /*|| (max.x > nodeMin.x && max.x < nodeMax.x && min.y > nodeMin.y && min.y < nodeMax.y) || (min.x > nodeMin.x && min.x < nodeMax.x && max.y > nodeMin.y && max.y < nodeMax.y) || (max.x > nodeMin.x && max.x < nodeMax.x && max.y > nodeMin.y && max.y < nodeMax.y) || (min.x > nodeMin.x && min.x < nodeMin.x && max.y > nodeMin.y && max.y < nodeMax.y)*/
//                    
//                    if (isInside) {
////                        print(isStable)
//                        return BoundingBox3D(min: SCNVector3(), max: SCNVector3())
//                    }
//                    
//                }
//            }
            
//        let currentCameraPos = simd_float3(currentFrame.camera.transform.columns.3.x,
//                                           currentFrame.camera.transform.columns.3.y,
//                                           currentFrame.camera.transform.columns.3.z)
//        if let lastPos = lastCameraPos{
//            let movement = simd_distance(currentCameraPos, lastPos)
//            if movement > 0.01 {
//                print("undo creation")
//                return BoundingBox3D(min: SCNVector3(), max: SCNVector3())
//            }
//        }
//            let boundingBox = rectangleBoundingBox
        print("Drawing", rectangleBoundingBox)
        let wireframe = SCNNode()
        let rectangle = SCNPlane(width: worldWidth, height: worldHeight)
            
            //        let material = SCNMaterial()
            //        material.diffuse.contents = UIColor.blue
            //        rectangle.materials = [material]
//        print(worldWidth, worldHeight)
//        let sphereGeometry = SCNSphere(radius: 0.01)
        if (name == "end_point" || name == "label") {
            rectangle.firstMaterial?.diffuse.contents = UIColor.red
        } else if (name == "shelf") {
            rectangle.firstMaterial?.diffuse.contents = UIColor.blue
        } else {
            rectangle.firstMaterial?.diffuse.contents = UIColor.green
        }
//        let sphereNode = SCNNode(geometry: sphereGeometry)
//        sphereNode.position = rectangleBoundingBox
            rectangle.firstMaterial?.isDoubleSided = true
            wireframe.geometry = rectangle
            setupShaderOnGeometry(rectangle)
            wireframe.position = worldPosition
            let billboardConstraint = SCNBillboardConstraint()
            wireframe.constraints = [billboardConstraint]
            
            // Create SCNText geometry
            let textGeometry = SCNText(string: "\(label)", extrusionDepth: 0)
            
            // Set the font and size of the text
        textGeometry.font = UIFont.systemFont(ofSize: CGFloat(0.7))
            
            // Create a node with the SCNText geometry
            let textNode = SCNNode(geometry: textGeometry)
            
            // Set the position of the text node in the AR world
        textNode.position = rectangleBoundingBox.min
            
            // Optionally, adjust the scale of the text
            textNode.scale = SCNVector3(0.005, 0.005, 0.005) // Scale to make it visible
            let material = SCNMaterial()
        if (name == "end_point" || name == "label") {
            material.diffuse.contents = UIColor.red
        } else if (name == "shelf") {
            material.diffuse.contents = UIColor.blue
        } else {
            material.diffuse.contents = UIColor.green
        }
            material.diffuse.contents = UIColor.green // Set text color
            textGeometry.firstMaterial = material
            
            textNode.constraints = [billboardConstraint]
            
            //        // Create a box geometry with dynamic size
            //        let box = SCNBox(width: width, height: height, length: depth, chamferRadius: 0)
            //
            //        let material = SCNMaterial()
            //        material.diffuse.contents = UIColor.red
            //        material.fillMode = .lines
            //
            //        box.firstMaterial = material
            //
            //        let boxNode = SCNNode(geometry: box)
            //        boxNode.position = SCNVector3(0, 0, 0.5)// Align with the detected object's position
            //
//        let anchorPosition = simd_float4x4(simd_float4(1, 0, 0, 0),
//                                           simd_float4(0, 1, 0, 0),
//                                           simd_float4(0, 0, 1, 0),
//                                           simd_float4(centre.x, centre.y, centre.z, 1))
//            let anchor = ARAnchor(transform: anchorPosition)
//            self.sceneView?.session.add(anchor: anchor)
        self.sceneView?.scene.rootNode.addChildNode(wireframe)
        self.sceneView?.scene.rootNode.addChildNode(textNode)
//            print("This is how you draw boxes !")
    }
    
    func setupShaderOnGeometry(_ geometry: SCNPlane) {
        guard let path = Bundle.main.path(forResource: "wireframe_shader", ofType: "metal", inDirectory: "art.scnassets"),
                    let shader = try? String(contentsOfFile: path, encoding: .utf8) else {

                        return
                }

        geometry.firstMaterial?.shaderModifiers = [.surface: shader]
    }

    
    func convert2DTo3D(box: CGRect, in sceneView: ARSCNView) -> SCNVector3? {
        let boxCenter = CGPoint(x: box.midX, y: box.midY)
        let hitTestResults = sceneView.hitTest(boxCenter, types: [.featurePoint, .estimatedHorizontalPlane])
        
        if let result = hitTestResults.first {
            let position = SCNVector3(result.worldTransform.columns.3.x,
                                      result.worldTransform.columns.3.y,
                                      result.worldTransform.columns.3.z)
            return position
        }
        
        return nil
    }
  
    // Place the blue 3D surface.
    func placeARObject(at position: SCNVector3) {

        let width: CGFloat = 0.1
        let height: CGFloat = 0.1
        let length: CGFloat = 0.1
        

        let vertices: [SCNVector3] = [
            SCNVector3(-width / 2, -height / 2, -length / 2),
            SCNVector3(width / 2, -height / 2, -length / 2),
            SCNVector3(width / 2, height / 2, -length / 2),
            SCNVector3(-width / 2, height / 2, -length / 2),
            SCNVector3(-width / 2, -height / 2, length / 2),
            SCNVector3(width / 2, -height / 2, length / 2),
            SCNVector3(width / 2, height / 2, length / 2),
            SCNVector3(-width / 2, height / 2, length / 2)
        ]
        

        let edges: [(Int, Int)] = [
            (0, 1), (1, 2), (2, 3), (3, 0),
            (4, 5), (5, 6), (6, 7), (7, 4),
            (0, 4), (1, 5), (2, 6), (3, 7)
        ]
        
        let lineNodes = edges.map { edge in
            let startVertex = vertices[edge.0]
            let endVertex = vertices[edge.1]
            return createLine(from: startVertex, to: endVertex)
        }
        
        for node in lineNodes {
            node.position = position
            sceneView?.scene.rootNode.addChildNode(node)
        }
    }


    func createLine(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
        let lineGeometry = SCNGeometry.line(from: start, to: end)
        let lineNode = SCNNode(geometry: lineGeometry)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        lineGeometry.materials = [material]
        return lineNode
    }
  
    
    func boundingBoxOverlap3D(box1: BoundingBox3D, box2: BoundingBox3D) -> Float {

        let overlapX = max(0, min(box1.max.x, box2.max.x) - max(box1.min.x, box2.min.x))
        let overlapY = max(0, min(box1.max.y, box2.max.y) - max(box1.min.y, box2.min.y))
        let overlapZ = max(0, min(box1.max.z, box2.max.z) - max(box1.min.z, box2.min.z))

        if overlapX == 0 || overlapY == 0 || overlapZ == 0 {
            return 0
        }
        
        let intersectionVolume = overlapX * overlapY * overlapZ
        
        let volumeBox1 = (box1.max.x - box1.min.x) * (box1.max.y - box1.min.y) * (box1.max.z - box1.min.z)
        let volumeBox2 = (box2.max.x - box2.min.x) * (box2.max.y - box2.min.y) * (box2.max.z - box2.min.z)
        
        let unionVolume = volumeBox1 + volumeBox2 - intersectionVolume

        return intersectionVolume / unionVolume
    }
    
    func trackProduct(label: String, position: SCNVector3, convertedRect: CGRect, objectDetect: ObjectDetect, cameraPosition: simd_float4x4) -> Bool {
//        if objectDetectionHelper.detectedProducts.count == 0 && detectedProducts.count > 0 {
//            detectedProducts.removeAll()
//        }
        let uuid = UUID()
        guard let overlayView = self.sceneView else { return false}
//        let boundingBox = drawRectangleInAR(at: position, convertedRect: convertedRect, cameraPosition: cameraPosition, objectDetect: objectDetect, currentFrame: frame)
//        if boundingBox.min == SCNVector3() && boundingBox.max == SCNVector3() {
//            // The bounding box is like the default BoundingBox3D with zero min and max
//            return false
//        }
//        let convertedRect = convertBoundingBox3DToCGRect(boundingBox: boundingBox, sceneView: overlayView)
//        
//        
//        //        for (existingUUID, savedProduct) in detectedProducts {
//        //            let savedBoundingBox = savedProduct.boundingBox3D
//        //            let closestBox = convertBoundingBox3DToCGRect(boundingBox: savedBoundingBox, sceneView: overlayView)
//        //
//        //            guard let closestBox = closestBox else { continue }
//        //            guard let convertedRect = convertedRect else { continue }
//        //
//        ////            show3DPoint(at: position)
//        ////            if position.isPointInsideBoundingBox(boundingBox: savedBoundingBox) {
//        //////                print("\(label) already detected. Skipping.")
//        ////                return
//        ////            }
//        //        }
//        //        print("------------------ add \(uuid)")
//        
//        // Nếu chưa tồn tại trong danh sách, thêm vào
//        detectedProducts[uuid] = ObjectDetectionProduct(position: position, boundingBox3D: boundingBox, name: objectDetect.name)
//        objectDetectionHelper.detectedProducts.append(objectDetect)
//        //        print("New \(label) detected at \(position).")
        return true
    }
    
    func show3DPoint(at position: SCNVector3) {

//        let sphere = SCNSphere(radius: 0.0015)
//        
//    // Create a box geometry with dynamic size
//        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
//        
////        let material = SCNMaterial()
////        material.diffuse.contents = UIColor.clear
////        material.fillMode = .lines
////        
////        box.firstMaterial = material
////        
////        let boxNode = SCNNode(geometry: box)
////        boxNode.position = node.position // Align with the detected object's position
//            
//
//        let material = SCNMaterial()
//        material.diffuse.contents = UIColor.red
//        sphere.materials = [material]
//        
//
//        let pointNode = SCNNode(geometry: sphere)
//        
//        pointNode.position = position
//        
//        self.sceneView?.scene.rootNode.addChildNode(pointNode)
    }
    
    func convertRectToBoundingBox3D(rect: CGRect) -> BoundingBox3D {

        let depth: Float = 0.1
        
        let min = SCNVector3(x: Float(rect.minX), y: Float(rect.minY), z: 0)
        let max = SCNVector3(x: Float(rect.maxX), y: Float(rect.maxY), z: depth)
        
        return BoundingBox3D(min: min, max: max)
    }
    
    func addProductLabel(label: String, position: SCNVector3, convertedRect: CGRect) {
        guard let overlayView = self.sceneView else { return }

        let center2D = CGPoint(x: convertedRect.midX, y: convertedRect.midY)
        
        let hitTestResults = overlayView.hitTest(center2D, types: [.existingPlaneUsingExtent])
        guard let result = hitTestResults.first else {
            print("Không tìm thấy vị trí 3D phù hợp.")
            return
        }
        let position3D = SCNVector3(result.worldTransform.columns.3.x,
                                    result.worldTransform.columns.3.y,
                                    result.worldTransform.columns.3.z)
        

        let textGeometry = SCNText(string: label, extrusionDepth: 0.2)
        textGeometry.font = UIFont.systemFont(ofSize: 12)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.blue

        let textNode = SCNNode(geometry: textGeometry)
        
        let boundingBox = textGeometry.boundingBox
        let width = boundingBox.max.x - boundingBox.min.x
        let height = boundingBox.max.y - boundingBox.min.y
        textNode.pivot = SCNMatrix4MakeTranslation(width / 2, height / 2, 0)
        
        textNode.position = SCNVector3(position3D.x, position3D.y, position3D.z)
        textNode.scale = SCNVector3(0.01, 0.01, 0.01) // Thu nhỏ kích thước
        
        overlayView.scene.rootNode.addChildNode(textNode)
    }
}

extension CVPixelBuffer {
  /// Returns thumbnail by cropping pixel buffer to biggest square and scaling the cropped image
  /// to model dimensions.
  func resized(to size: CGSize ) -> CVPixelBuffer? {

    let imageWidth = CVPixelBufferGetWidth(self)
    let imageHeight = CVPixelBufferGetHeight(self)

    let pixelBufferType = CVPixelBufferGetPixelFormatType(self)

    assert(pixelBufferType == kCVPixelFormatType_32BGRA ||
           pixelBufferType == kCVPixelFormatType_32ARGB)

    let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)
    let imageChannels = 4

    CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

    // Finds the biggest square in the pixel buffer and advances rows based on it.
    guard let inputBaseAddress = CVPixelBufferGetBaseAddress(self) else {
      return nil
    }

    // Gets vImage Buffer from input image
    var inputVImageBuffer = vImage_Buffer(data: inputBaseAddress, height: UInt(imageHeight), width: UInt(imageWidth), rowBytes: inputImageRowBytes)

    let scaledImageRowBytes = Int(size.width) * imageChannels
    guard  let scaledImageBytes = malloc(Int(size.height) * scaledImageRowBytes) else {
      return nil
    }

    // Allocates a vImage buffer for scaled image.
    var scaledVImageBuffer = vImage_Buffer(data: scaledImageBytes, height: UInt(size.height), width: UInt(size.width), rowBytes: scaledImageRowBytes)

    // Performs the scale operation on input image buffer and stores it in scaled image buffer.
    let scaleError = vImageScale_ARGB8888(&inputVImageBuffer, &scaledVImageBuffer, nil, vImage_Flags(0))

    CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

    guard scaleError == kvImageNoError else {
      return nil
    }

    let releaseCallBack: CVPixelBufferReleaseBytesCallback = {mutablePointer, pointer in

      if let pointer = pointer {
        free(UnsafeMutableRawPointer(mutating: pointer))
      }
    }

    var scaledPixelBuffer: CVPixelBuffer?

    // Converts the scaled vImage buffer to CVPixelBuffer
    let conversionStatus = CVPixelBufferCreateWithBytes(nil, Int(size.width), Int(size.height), pixelBufferType, scaledImageBytes, scaledImageRowBytes, releaseCallBack, nil, nil, &scaledPixelBuffer)

    guard conversionStatus == kCVReturnSuccess else {

      free(scaledImageBytes)
      return nil
    }
//      let ciImageDepth  = CIImage(cvPixelBuffer: scaledPixelBuffer!)
//              let contextDepth:CIContext  = CIContext.init(options: nil)
//              let cgImageDepth:CGImage    = contextDepth.createCGImage(ciImageDepth, from: ciImageDepth.extent)!
//              let uiImageDepth:UIImage    = UIImage(cgImage: cgImageDepth, scale: 1, orientation: UIImage.Orientation.up)
//      
//              // Save UIImage to Photos Album
//              UIImageWriteToSavedPhotosAlbum(uiImageDepth, nil, nil, nil)

    return scaledPixelBuffer
  }

}

extension SCNGeometry {
    class func line(from start: SCNVector3, to end: SCNVector3) -> SCNGeometry {

        let vertices: [SCNVector3] = [start, end]
        
        let source = SCNGeometrySource(vertices: vertices)
        
        let indices: [Int32] = [0, 1]
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)

        return SCNGeometry(sources: [source], elements: [element])
    }
}

extension ARSCNView {

    func worldPosition(from point: CGPoint) -> SCNVector3? {

        let raycastQuery = raycastQuery(from: point, allowing: .estimatedPlane, alignment: .vertical)
        
        guard let raycastQuery = raycastQuery else {
//            print("raycastQuery nil")
            return nil
        }

        guard let raycastResult = session.raycast(raycastQuery).first else {
//            print("raycastResult nil")
            return nil
        }

        let worldPosition = raycastResult.worldTransform.columns.3
        return SCNVector3(worldPosition.x, worldPosition.y, worldPosition.z)
    }
}
extension SCNVector3: Equatable {
    public static func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}

extension SCNVector3 {
    func distance(to vector: SCNVector3) -> Float {
        let dx = x - vector.x
        let dy = y - vector.y
        let dz = z - vector.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    func isPointInsideBoundingBox(boundingBox: BoundingBox3D) -> Bool {
        return self.x >= boundingBox.min.x && self.x <= boundingBox.max.x &&
        self.y >= boundingBox.min.y && self.y <= boundingBox.max.y &&
        self.z >= boundingBox.min.z && self.z <= boundingBox.max.z
    }
}


extension ARSession {
    func resizeTo(_ sceneView: ARSCNView)->CIImage?{
        guard let frame = self.currentFrame else { return nil }
        let viewPort = sceneView.bounds
        let viewPortSize = sceneView.bounds.size
        let imageBuffer = frame.capturedImage
        let imageSize = CGSize(width: CVPixelBufferGetWidth(imageBuffer), height: CVPixelBufferGetHeight(imageBuffer))
        let interfaceOrientation = UIApplication.shared.keyWindow?.windowScene!.interfaceOrientation ?? .portrait
        let image = CIImage(cvImageBuffer: imageBuffer)
        let normalizeTransform = CGAffineTransform(scaleX: 1.0/imageSize.width, y: 1.0/imageSize.height)
        let flipTransform = interfaceOrientation.isPortrait ? CGAffineTransform(scaleX: -1, y: -1).translatedBy(x: -1, y: -1) : .identity
//        let viewPort = CGRect.init(origin: CGPoint.zero, size: size)
//        let displayTransform = frame.displayTransform(for: interfaceOrientation, viewportSize: viewPortSize)
        let displayTransform = frame.displayTransform(for: interfaceOrientation, viewportSize: viewPortSize)
        let toViewPortTransform = CGAffineTransform(scaleX: viewPortSize.width, y: viewPortSize.height)
        return image.transformed(by: normalizeTransform.concatenating(flipTransform).concatenating(displayTransform).concatenating(toViewPortTransform)).cropped(to: viewPort)
    }
}

struct BoundingBox3D {
    var min: SCNVector3
    var max: SCNVector3 
}

struct ObjectDetectionProduct {
    var position: SCNVector3
    var boundingBox3D: BoundingBox3D
    var name: String
}
