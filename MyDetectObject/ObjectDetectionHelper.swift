
import TensorFlowLiteTaskVision
import TensorFlowLite
import Accelerate

struct Result {
  let inferenceTime: Double
  let detections: [Detection]
}

struct Label: Codable {
    let id: Int
    let name: String
}

/// Information about a model file or labels file.
typealias FileInfo = (name: String, extension: String)

/// This class handles all data preprocessing and makes calls to run inference on a given frame
/// by invoking the `ObjectDetector`.
public class ObjectDetectionHelper: ObservableObject {
    

    private var detector: ObjectDetector?
    @Published var scoreThreshold : Float = ConstantsDefault.scoreThreshold
    @Published var modelType: ModelType = ConstantsDefault.modelType
    @Published var jsonType: String = ConstantsDefault.jsonType
    @Published var imagePreview: UIImage? = nil
    @Published var detectedProducts: [ObjectDetect] = []
    
    var maxResults : Int = ConstantsDefault.maxResults
    var threadCount : Int = ConstantsDefault.threadCount
    
    private var interpreter: Interpreter?
    var labels: [String] = []
    
    private var tensorWidth = 0
    private var tensorHeight = 0
    private var numChannels = 0
    private var numElements = 0
    
    private var inputWidth = 640
    private var inputHeight = 640
    private var inputChannels = 3
    private var batchSize = 1
    
    private let bgraPixel = (channels: 4, alphaComponent: 3, lastBgrComponent: 2)
    private let rgbPixelChannels = 3
    private let colorStrideValue = 10
    
    public var sceneImage: CVPixelBuffer?

  private let colors = [
    UIColor.black,  // 0.0 white
    UIColor.darkGray,  // 0.333 white
    UIColor.lightGray,  // 0.667 white
    UIColor.white,  // 1.0 white
    UIColor.gray,  // 0.5 white
    UIColor.red,  // 1.0, 0.0, 0.0 RGB
    UIColor.green,  // 0.0, 1.0, 0.0 RGB
    UIColor.blue,  // 0.0, 0.0, 1.0 RGB
    UIColor.cyan,  // 0.0, 1.0, 1.0 RGB
    UIColor.yellow,  // 1.0, 1.0, 0.0 RGB
    UIColor.magenta,  // 1.0, 0.0, 1.0 RGB
    UIColor.orange,  // 1.0, 0.5, 0.0 RGB
    UIColor.purple,  // 0.5, 0.0, 0.5 RGB
    UIColor.brown,  // 0.6, 0.4, 0.2 RGB
  ]
    
    var combinedProperties: String {
        "\(modelType)-\(scoreThreshold)-\(maxResults)"
    }
    
    func clearDetectedProducts() {
        print(detectedProducts)
        detectedProducts.removeAll()
    }
    
//    init() {
//        let modelFilename = self.modelType.modelFileInfo.name
//        // Construct the path to the model file.
//        guard
//            let modelPath = Bundle.main.path(
//                forResource: modelType.modelFileInfo.name,
//                ofType: modelType.modelFileInfo.extension
//            )
//        else{
//            print("Failed to load the model file with name: \(modelFilename).")
//            return
//        }
//        print(modelPath)
//        labels = loadClassNames(from: "labels 2")!
//        
//        var options = Interpreter.Options()
//        options.threadCount = 5
//        
//        do {
//            // Create the `Detector`.
//            self.interpreter = try Interpreter(modelPath: modelPath, options: options)
////            try interpreter?.allocateTensors()
//            print("works")
//        } catch let error {
//            print("Failed to create the interpreter with error: \(error.localizedDescription)")
//            return
//        }
//    }

    func setup() { // Set the TFL Properties.
        DispatchQueue.main.async {
            self.detectedProducts.removeAll()
        }
//        let modelFilename = self.modelType.modelFileInfo.name
//         Construct the path to the model file.
        guard
            let modelPath = DetectObjectSDK.shared.modelPath
        else{
            print("Failed to load the model file.")
            return
        }
        
//        guard
//            let modelPath = Bundle.main.path(
//                forResource: modelType.modelFileInfo.name,
//                ofType: modelType.modelFileInfo.extension
//            )
//        else{
//            print("Failed to load the model file with name: \(modelFilename).")
//            return
//        }
        
        labels = loadClassNames(from: "output_float32_labels")!
        
        // Specify the options for the `Detector`.
        //      self.scoreThreshold = scoreThreshold
        var options = Interpreter.Options()
        //        options.classificationOptions.scoreThreshold = scoreThreshold
        //        options.classificationOptions.maxResults = maxResults
        //      options.baseOptions.computeSettings.cpuSettings.numThreads = Int(threadCount)
        
        //        let tflCoreMetal = TFLCoreMLDelegateSettings(coreMLVersion: 3, enableddevices: .TFLCoreMLDelegateSettings_DevicesAll)
        //        options.baseOptions.coreMLDelegateSettings = tflCoreMetal
        options.threadCount = 7
//        var mlOptions = CoreMLDelegate.Options()
//        mlOptions.enabledDevices = .all
//        var coreMLDelegate = CoreMLDelegate(options: mlOptions)
        
        do {
            // Create the `Detector`.
            self.interpreter = try Interpreter(modelPath: modelPath, options: options)
//            try interpreter?.allocateTensors()
//            let outputTensor = try self.interpreter?.output(at: 0)
//            let shape = outputTensor?.shape
//            numChannels = shape?.dimensions.first ?? 4
            print("works")
        } catch let error {
            print("Failed to create the interpreter with error: \(error.localizedDescription)")
            return
        }
        
        tensorWidth = 640
        tensorHeight = 640
        numChannels = 4
        numElements = 8400
        
        
      }
      
//      if  (options.baseOptions.coreMLDelegateSettings?.coreMLVersion == 3) {
//            print("Using CoreML")
//          } else {
//              print("Failed to initialize CoreMLDelegate. Falling back to CPU.")
//              options.baseOptions.computeSettings.cpuSettings.numThreads = Int(threadCount) // Fallback to CPU
//          }
//      
//    do {
//      // Create the `Detector`.
//        self.detector = try ObjectDetector.detector(options: options)
//        print("works")
//    } catch let error {
//      print("Failed to create the interpreter with error: \(error.localizedDescription)")
//        return
//    }
    
    func restart() {
        interpreter = nil
        
        guard
            let modelPath = DetectObjectSDK.shared.modelPath
        else{
            print("Failed to load the model file.")
            return
        }
        labels = loadClassNames(from: "output_float32_labels")!
        
//        let modelFilename = self.modelType.modelFileInfo.name
//        // Construct the path to the model file.
//        guard
//            let modelPath = Bundle.main.path(
//                forResource: modelType.modelFileInfo.name,
//                ofType: modelType.modelFileInfo.extension
//            )
//        else{
//            print("Failed to load the model file with name: \(modelFilename).")
//            return
//        }
        
        // Specify the options for the `Detector`.
        var options = Interpreter.Options()
        options.threadCount = 4
        var mlOptions = CoreMLDelegate.Options()
        mlOptions.enabledDevices = .all
        var coreMLDelegate = CoreMLDelegate(options: mlOptions)
                
        do {
          // Create the `Detector`.
            self.interpreter = try Interpreter(modelPath: modelPath, options: options)
            print("works")
        } catch let error {
          print("Failed to create the interpreter with error: \(error.localizedDescription)")
            return
        }
        
    }
    
    func close() {
        detectedProducts.removeAll()
        interpreter = nil
    }
    
    func detect(pixelBuffer: CVPixelBuffer) -> [ObjectDetect]? {
        //print("\(CVPixelBufferGetWidth(pixelBuffer))x\(CVPixelBufferGetHeight(pixelBuffer))")
        sceneImage = nil
        if (tensorWidth == 0 || tensorHeight == 0 || numChannels == 0 || numElements == 0) { return nil}
        //        guard let mlImage = MLImage(pixelBuffer: pixelBuffer) else { return nil }
        let imageChannels = 4
//        let ciImageDepth  = CIImage(cvPixelBuffer: pixelBuffer)
//                let contextDepth:CIContext  = CIContext.init(options: nil)
//                let cgImageDepth:CGImage    = contextDepth.createCGImage(ciImageDepth, from: ciImageDepth.extent)!
//                var uiImageDepth:UIImage    = UIImage(cgImage: cgImageDepth, scale: 1, orientation: UIImage.Orientation.up)
//        print(uiImageDepth.size)
//        var frameAux: UIImage = UIImage(cgImage: cgImageDepth.resize(size: CGSize(width: 640, height: 640))!)
//        let ciImageDepth  = CIImage(cvPixelBuffer: pixelBuffer)
//                let contextDepth:CIContext  = CIContext.init(options: nil)
//                let cgImageDepth:CGImage    = contextDepth.createCGImage(ciImageDepth, from: ciImageDepth.extent)!
//                let uiImageDepth:UIImage    = UIImage(cgImage: cgImageDepth, scale: 1, orientation: UIImage.Orientation.up)
//        
//                // Save UIImage to Photos Album
//                UIImageWriteToSavedPhotosAlbum(uiImageDepth, nil, nil, nil)
        let outputTensor: Tensor
        do {
            try interpreter?.allocateTensors() 
//            guard let rgbData = toData(&uiImageDepth)
//            else {print("Failed to convert image to rgb data"); return nil}
//            guard let rgbData = rgbDataFromBuffer(
//                pixelBuffer,
//                byteCount: batchSize * inputWidth * inputHeight * inputChannels
//            ) else { print("Failed to convert the image buffer to RGB data."); return nil }
            
//             Data to Tensor.
            guard let rgbData = convertBGRAtoRGBData(pixelBuffer: pixelBuffer) else {
                print("Failed to convert to RGB")
                             return nil}
//            normalizeBGRA(pixelBuffer: pixelBuffer)
//            guard let dat = cvPixelBufferToData(pixelBuffer: pixelBuffer) else {print("Failed to convert to data"); return nil}
            try interpreter?.copy(rgbData, toInputAt: 0)

//            let startDate = Date()
////            Run the TFL detection on the object.
//            let interval = Date().timeIntervalSince(startDate) * 1000 // Set the time for when the TFL detection inference was completed.
            // inference

            try interpreter?.invoke()
            outputTensor = try interpreter!.output(at: 0)
            numChannels = (outputTensor.shape.dimensions[1])
        } catch let error {
            print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
            return nil
        }
//        let outputData = outputTensor.data
        let results = ([Float](unsafeData: outputTensor.data) ?? [])
//        let results = outputTensor.data.toArray(type: Float32.self)
//        let results: [Float32] = outputData.withUnsafeBytes {
//            Array($0.bindMemory(to: Float32.self))
//        }

        if (results.count == 0 || results.count == 1) {
            return nil
        }
        
        let filteredBoxes = filterBox(results: results, pixelBuffer: pixelBuffer)
//        print(filteredBoxes.count)
        if (filteredBoxes.count == 0) {
            return nil
        }
        return filteredBoxes
    }
    
    private func filterBox(results: [Float32], pixelBuffer: CVPixelBuffer) -> [ObjectDetect] {
        var boxes: [ObjectDetect] = []
        var transposedArray = [Float](repeating: 0.0, count: numChannels*numElements)

        for row in 0..<numChannels {
            for col in 0..<numElements {
                let oldIndex = row * numElements + col   // Original index in [35, 8400]
                let newIndex = col * numChannels + row     // New index in [8400, 35]
                transposedArray[newIndex] = results[oldIndex]
            }
        }
        let outputRow = numElements
        let outputColumn = numChannels
        for i in 0..<outputRow {
            var maxConfidence = scoreThreshold
//            var j = 0
//            var arrayIndex = i + numElements*j
            var labelIndex = 0
            for j in 0..<outputColumn-4 {
//                print(results[j])
                if (transposedArray[i*outputColumn+4+j] > maxConfidence) {
//                        for k in 0..<outputColumn {
//                            print(transposedArray[i*outputColumn+k])
//                        }
                    maxConfidence = transposedArray[i*outputColumn+4+j]
//                    print(k)
                    labelIndex = j
                }
            }
            if (maxConfidence > scoreThreshold) {
                var className = labels[(labelIndex)]
                var conf = maxConfidence
                var cx = transposedArray[i*outputColumn]
                var cy = transposedArray[i*outputColumn+1]
                var w = transposedArray[i*outputColumn + 2]
                var h = transposedArray[i*outputColumn + 3]
                var x1 = cx - (w/2.0)
                var y1 = cy - (h/2.0)
                var x2 = cx + (w/2.0)
                var y2 = cy + (h/2.0)
//                if (x1 < 0.0 || x1 > 1.0) {i+=1; continue}
//                if (y1 < 0.0 || y1 > 1.0) {i+=1; continue}
//                if (x2 < 0.0 || x2 > 1.0) {i+=1; continue}
//                if (y2 < 0.0 || y2 > 1.0) {i+=1; continue}
                
                let item = ObjectDetect()
                item.left = x1*640
                item.top = y1*640
                item.right = x2*640
                item.bottom = y2*640
                item.w = w*640
                item.h = h*640
                item.crop = cropPixelBufferToBase64(pixelBuffer: pixelBuffer, x: CGFloat(item.left), y: CGFloat(item.top), width: CGFloat(item.w), height: CGFloat(item.h))
                item.name = "\(className)"
                item.conf = conf
//                print(item.left, item.top)
                // Create an ObjectDetect item and append it to boxes.
                boxes.append(item)
            }
        }
        return applyNMS(boxes: boxes)
    }
    
    func loadClassNames(from fileName: String) -> [String]? {
        // Locate the text file in the main bundle
        guard let url = DetectObjectSDK.shared.textPath else {
            print("Text file not found")
            return nil
        }
//        guard let url = Bundle.main.url(forResource: fileName, withExtension: "txt") else {
//            print("Text file not found")
//            return nil
//        }

        do {
            // Load the contents of the text file as a string
            let text = try String(contentsOf: url, encoding: .utf8)
            
            // Split the text by new lines to create an array of strings (class names)
            let classNames = text.split(separator: "\n").map { String($0) }
            return classNames
        } catch {
            print("Error reading text file: \(error)")
            return nil
        }
    }
}
func flattenTranspose(_ arr: [UInt8]) -> [Float32] {
    var res2 = [Float32](repeating: 0, count: 640*640*3)
    var intCounter = 0
    for k in 0...2{
        for i in 0...639{
            for j in 0...639{
                res2[intCounter] = Float32(arr[640*4*i + 4*j + k]) / Float32(255)
                intCounter += 1
            }
        }
    }
    return res2
}
func toData(_ img: inout UIImage) -> Data? {
    let pix = img.getPixelValues()!
    let pixFlat = flattenTranspose(pix)
    return Data(copyingBufferOf: pixFlat)
}
func normalizeBGRA(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
    // Lock the base address of the pixel buffer to safely access the data
    CVPixelBufferLockBaseAddress(pixelBuffer, [])

    // Get the base address, width, height, and bytes per row of the pixel buffer
    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
        print("Failed to get base address")
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        return nil
    }
    
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    
    // Create a new pixel buffer with the same dimensions and format (BGRA)
    var newPixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
        kCFAllocatorDefault,
        width,
        height,
        kCVPixelFormatType_32BGRA,
        nil, // use default attributes
        &newPixelBuffer
    )
    
    guard status == kCVReturnSuccess, let outputPixelBuffer = newPixelBuffer else {
        print("Failed to create new pixel buffer")
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        return nil
    }
    
    // Lock the base address of the new pixel buffer
    CVPixelBufferLockBaseAddress(outputPixelBuffer, [])
    
    // Get the base address of the new pixel buffer
    guard let outputBaseAddress = CVPixelBufferGetBaseAddress(outputPixelBuffer) else {
        print("Failed to get base address of new pixel buffer")
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        CVPixelBufferUnlockBaseAddress(outputPixelBuffer, [])
        return nil
    }
    
    // Iterate through the pixel buffer and normalize the RGB values while preserving the alpha channel
    for y in 0..<height {
        // Get the pointer to the start of the current row
        let rowData = baseAddress.advanced(by: y * bytesPerRow)
        let outputRowData = outputBaseAddress.advanced(by: y * bytesPerRow)
        
        // Process each pixel in the row
        for x in 0..<width {
            let pixel = rowData.advanced(by: x * 4) // Each pixel has 4 components: B, G, R, A
            let outputPixel = outputRowData.advanced(by: x * 4)
            
            // Extract BGRA components
            let b = pixel.load(fromByteOffset: 0, as: UInt8.self)
            let g = pixel.load(fromByteOffset: 1, as: UInt8.self)
            let r = pixel.load(fromByteOffset: 2, as: UInt8.self)
            let a = pixel.load(fromByteOffset: 3, as: UInt8.self)
            
            // Normalize RGB (divide by 255)
            let normalizedR = Float(r) / 255.0
            let normalizedG = Float(g) / 255.0
            let normalizedB = Float(b) / 255.0
            
            // Rebuild the pixel with normalized RGB and the original alpha value
            outputPixel.storeBytes(of: UInt8(normalizedB * 255), toByteOffset: 0, as: UInt8.self) // Blue
            outputPixel.storeBytes(of: UInt8(normalizedG * 255), toByteOffset: 1, as: UInt8.self) // Green
            outputPixel.storeBytes(of: UInt8(normalizedR * 255), toByteOffset: 2, as: UInt8.self) // Red
            outputPixel.storeBytes(of: a, toByteOffset: 3, as: UInt8.self) // Alpha remains unchanged
        }
    }

    // Unlock the base addresses
    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
    CVPixelBufferUnlockBaseAddress(outputPixelBuffer, [])
    let ciImageDepth  = CIImage(cvPixelBuffer: outputPixelBuffer)
            let contextDepth:CIContext  = CIContext.init(options: nil)
            let cgImageDepth:CGImage    = contextDepth.createCGImage(ciImageDepth, from: ciImageDepth.extent)!
            let uiImageDepth:UIImage    = UIImage(cgImage: cgImageDepth, scale: 1, orientation: UIImage.Orientation.up)
    
            // Save UIImage to Photos Album
            UIImageWriteToSavedPhotosAlbum(uiImageDepth, nil, nil, nil)

    return outputPixelBuffer
}


func convertBGRAtoRGBData(pixelBuffer: CVPixelBuffer) -> Data? {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
        print("Failed to get base address")
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        return nil
    }

    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)
    let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    let bgraBytesPerPixel = 4
    let totalPixels = width * height

    var normalizedRGB = Data(capacity: totalPixels * 3 * MemoryLayout<Float>.size)

    let bgraPointer = baseAddress.assumingMemoryBound(to: UInt8.self)

    for i in 0..<totalPixels {
        let bgraOffset = i * bgraBytesPerPixel

        let b = Float(bgraPointer[bgraOffset]) / 255.0  // Blue
        let g = Float(bgraPointer[bgraOffset + 1]) / 255.0 // Green
        let r = Float(bgraPointer[bgraOffset + 2]) / 255.0 // Red

        var rFloat = r
        var gFloat = g
        var bFloat = b

        normalizedRGB.append(UnsafeBufferPointer(start: &rFloat, count: 1))
        normalizedRGB.append(UnsafeBufferPointer(start: &gFloat, count: 1))
        normalizedRGB.append(UnsafeBufferPointer(start: &bFloat, count: 1))
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
//    let floatArray = normalizedRGB.withUnsafeBytes {
//        Array(UnsafeBufferPointer<Float>(start: $0.baseAddress!.assumingMemoryBound(to: Float.self), count: normalizedRGB.count / MemoryLayout<Float>.size))
//        }
    // Return the RGB data as a Data object
//    rgbDataToPixelBuffer(floatArray, width: 640, height: 640)
    return normalizedRGB
}

func cropPixelBufferToBase64(
    pixelBuffer: CVPixelBuffer,
    x: CGFloat,
    y: CGFloat,
    width: CGFloat,
    height: CGFloat
) -> String? {
    // 1. Convert CVPixelBuffer to CIImage
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

    // 2. Define cropping rect (make sure it’s within bounds)
    let cropRect = CGRect(x: x, y: y, width: width, height: height)

    // 3. Crop the CIImage
    let cropped = ciImage.cropped(to: cropRect)

    // 4. Render cropped CIImage to CGImage
    let context = CIContext()
    guard let cgImage = context.createCGImage(cropped, from: cropped.extent) else {
        return nil
    }

    // 5. Convert CGImage → UIImage
    let uiImage = UIImage(cgImage: cgImage)

    // 6. Convert UIImage to JPEG/PNG Data
    guard let imageData = uiImage.jpegData(compressionQuality: 0.9) else {
        return nil
    }

    // 7. Encode to Base64
    return imageData.base64EncodedString()
}

func rgbDataToPixelBuffer(_ rgbData: [Float], width: Int, height: Int) -> CVPixelBuffer? {
    let pixelFormat = kCVPixelFormatType_32BGRA // Using BGRA format
    var pixelBuffer: CVPixelBuffer?
    
    let attributes: [CFString: Any] = [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true
    ]
    
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     width,
                                     height,
                                     pixelFormat,
                                     attributes as CFDictionary,
                                     &pixelBuffer)

    guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
        print("Error: Could not create CVPixelBuffer")
        return nil
    }

    CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))

    guard let pixelData = CVPixelBufferGetBaseAddress(buffer) else {
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        return nil
    }

    let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
    let bufferPtr = pixelData.assumingMemoryBound(to: UInt8.self)

    for y in 0..<height {
        for x in 0..<width {
            let rgbOffset = (y * width + x) * 3 // 3 floats per pixel in RGB
            let bgraOffset = y * bytesPerRow + x * 4 // 4 bytes per pixel in BGRA

            // Safe conversion: Multiply by 255, round, clamp, and cast to UInt8
            let r = UInt8(clamping: Int((rgbData[rgbOffset] * 255).rounded()))
            let g = UInt8(clamping: Int((rgbData[rgbOffset + 1] * 255).rounded()))
            let b = UInt8(clamping: Int((rgbData[rgbOffset + 2] * 255).rounded()))

            bufferPtr[bgraOffset] = b
            bufferPtr[bgraOffset + 1] = g
            bufferPtr[bgraOffset + 2] = r
            bufferPtr[bgraOffset + 3] = 255 // Alpha channel
        }
    }

    CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
    let ciImageDepth  = CIImage(cvPixelBuffer: pixelBuffer!)
            let contextDepth:CIContext  = CIContext.init(options: nil)
            let cgImageDepth:CGImage    = contextDepth.createCGImage(ciImageDepth, from: ciImageDepth.extent)!
            let uiImageDepth:UIImage    = UIImage(cgImage: cgImageDepth, scale: 1, orientation: UIImage.Orientation.up)
    
            // Save UIImage to Photos Album
            UIImageWriteToSavedPhotosAlbum(uiImageDepth, nil, nil, nil)
    return pixelBuffer
}

private func applyNMS(boxes: [ObjectDetect]) -> [ObjectDetect] {

    var sortedBoxes = boxes.sorted {$0.conf > $1.conf}
    var selectedBoxes: [ObjectDetect] = []
    
    while (!sortedBoxes.isEmpty) {
        var first = sortedBoxes.removeFirst()
        selectedBoxes.append(first)
        
        var index = 0
        while index < sortedBoxes.count {
            let box = sortedBoxes[index]
            var iou = calculateIOU(box1: first, box2: box)
            if (iou >= Float(0.6)) {
                sortedBoxes.remove(at: index)
            }
//            else {print(sortedBoxes[index].name)}
            index += 1
        }
    }
    
    let bxs = selectedBoxes
    for box in bxs {
//        print(box.conf, box.w, box.h)
    }
    return bxs
}

func limitDetections(detections: [ObjectDetect]) -> [ObjectDetect] {
    // Sort detections by confidence (descending)
    let sortedDetections = detections.sorted { $0.conf > $1.conf }
    
    // Return the top 'maxCount' detections
    return Array(sortedDetections.prefix(50))
}

private func calculateIOU(box1: ObjectDetect, box2: ObjectDetect) -> Float {
    var x1 = max(box1.left, box2.left)
    var y1 = max(box1.top, box2.top)
    var x2 = min(box1.right, box2.right)
    var y2 = min(box1.bottom, box2.bottom)
    
    var intersectionArea = max(Float(0), x2-x1) * max(Float(0), y2-y1)
    var box1Area = box1.w * box1.h
    var box2Area = box2.w * box2.h
    
    return intersectionArea / (box1Area + box2Area - intersectionArea)
}

private func rgbDataFromBuffer(
    _ buffer: CVPixelBuffer,
    byteCount: Int
) -> Data? {
    CVPixelBufferLockBaseAddress(buffer, .readOnly)
            defer {
                CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
            }
            guard let sourceData = CVPixelBufferGetBaseAddress(buffer) else {
                return nil
            }
            
            let width = CVPixelBufferGetWidth(buffer)
            let height = CVPixelBufferGetHeight(buffer)
            let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            let destinationChannelCount = 3
            let destinationBytesPerRow = destinationChannelCount * width
            
            var sourceBuffer = vImage_Buffer(data: sourceData,
                                             height: vImagePixelCount(height),
                                             width: vImagePixelCount(width),
                                             rowBytes: sourceBytesPerRow)
            
            guard let destinationData = malloc(height * destinationBytesPerRow) else {
                print("Error: out of memory")
                return nil
            }
            
            defer {
                free(destinationData)
            }
            
            var destinationBuffer = vImage_Buffer(data: destinationData,
                                                  height: vImagePixelCount(height),
                                                  width: vImagePixelCount(width),
                                                  rowBytes: destinationBytesPerRow)
            
            if (CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA){
                vImageConvert_BGRA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
            } else if (CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32ARGB) {
                vImageConvert_ARGB8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
            }
            
            let byteData = Data(bytes: destinationBuffer.data, count: destinationBuffer.rowBytes * height)
            
            // Not quantized, convert to floats
            let bytes = Array<UInt8>(unsafeData: byteData)!
            var floats = [Float]()
            for i in 0..<bytes.count {
                floats.append(Float(Float(bytes[i])/255))
            }
            return Data(copyingBufferOf: floats)
    }

private func loadJSONFromFile(named fileName: String) -> [Label]? {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
        print("JSON file not found")
        return nil
    }

    do {
        let data = try Data(contentsOf: url)
        let labels = try JSONDecoder().decode([Label].self, from: data)
        return labels
    } catch {
        print("Error decoding JSON: \(error)")
        return nil
    }
}

//func cvPixelBufferToData(pixelBuffer: CVPixelBuffer) -> Data? {
//    // Lock the pixel buffer for reading
//        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
//        
//        // Get the base address of the pixel buffer
//        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
//        
//        // Get the bytes per row and the height of the pixel buffer
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//        let height = CVPixelBufferGetHeight(pixelBuffer)
//        
//        // Create Data from the base address, bytes per row, and height
//        let data = Data(bytes: baseAddress!, count: bytesPerRow * height)
//        
//        // Unlock the pixel buffer
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
//    
////    convertDataToCVPixelBuffer(data: data, width: 960, height: 1280)
//    return data
//}
//func convertDataToCVPixelBuffer(data: Data, width: Int, height: Int) -> CVPixelBuffer? {
//    // Create a pixel buffer with the appropriate dimensions and format
//        var pixelBuffer: CVPixelBuffer?
//        
//        let attributes: [CFString: Any] = [
//            kCVPixelBufferCGImageCompatibilityKey: true,
//            kCVPixelBufferCGBitmapContextCompatibilityKey: true
//        ]
//        
//        let status = CVPixelBufferCreate(nil,
//                                         width,
//                                         height,
//                                         kCVPixelFormatType_32BGRA,
//                                         attributes as CFDictionary,
//                                         &pixelBuffer)
//        
//        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
//            return nil
//        }
//        
//        // Lock the pixel buffer for writing
//    CVPixelBufferLockBaseAddress(buffer, .readOnly)
//        
//        // Get the base address of the pixel buffer
//        let baseAddress = CVPixelBufferGetBaseAddress(buffer)
//        
//        // Get the bytes per row of the pixel buffer
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
//        
//        // Copy the data into the pixel buffer
//        data.withUnsafeBytes { (rawBufferPointer) in
//            guard let pointer = rawBufferPointer.baseAddress else { return }
//            memcpy(baseAddress, pointer, data.count)
//        }
//        
//        // Unlock the pixel buffer
//    CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
//    
//    let ciImageDepth  = CIImage(cvPixelBuffer: buffer)
//                let contextDepth:CIContext  = CIContext.init(options: nil)
//                let cgImageDepth:CGImage    = contextDepth.createCGImage(ciImageDepth, from: ciImageDepth.extent)!
//                let uiImageDepth:UIImage    = UIImage(cgImage: cgImageDepth, scale: 1, orientation: UIImage.Orientation.up)
//    
//                // Save UIImage to Photos Album
//                UIImageWriteToSavedPhotosAlbum(uiImageDepth, nil, nil, nil)
//    
//    return buffer
//}

// MARK: - Extensions

extension UIImage {
    func getPixelValues() -> [UInt8]? {
                let size = self.size
                var width = 0
                var height = 0
                
                width = Int(size.width)
                height = Int(size.height)
                let bitsPerComponent = 8
                let bytesPerRow = width * 4
                let totalBytes = height * bytesPerRow
                let bitmapInfo = self.cgImage?.bitmapInfo

                let colorSpace = CGColorSpaceCreateDeviceRGB()
                var pixelValues = [UInt8](repeating: 0, count: totalBytes)

                let contextRef = CGContext(data: &pixelValues,
                                          width: width,
                                         height: height,
                               bitsPerComponent: bitsPerComponent,
                                    bytesPerRow: bytesPerRow,
                                          space: colorSpace,
                                     bitmapInfo: bitmapInfo!.rawValue)
                contextRef?.draw(self.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
                return pixelValues
        }
}


extension Data {
    /// Creates a new buffer by copying the buffer pointer of the given array.
    ///
    /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
    ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
    ///     data from the resulting buffer has undefined behavior.
    /// - Parameter array: An array with elements of type `T`.
    init<T>(copyingBufferOf array: [T]) {
        self = array.withUnsafeBufferPointer(Data.init)
    }
    
    func toArray<T>(type: T.Type) -> [T] where T: ExpressibleByIntegerLiteral {
        var array = [T](repeating: 0, count: self.count/MemoryLayout<T>.stride)
        _ = array.withUnsafeMutableBytes { copyBytes(to: $0) }
        return array
    }
}

extension Array {
    /// Creates a new array from the bytes of the given unsafe data.
    ///
    /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
    ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
    ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
    /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
    ///     `MemoryLayout<Element>.stride`.
    /// - Parameter unsafeData: The data containing the bytes to turn into an array.
    init?(unsafeData: Data) {
        guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
#if swift(>=5.0)
        self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
#else
        self = unsafeData.withUnsafeBytes {
            .init(UnsafeBufferPointer<Element>(
                start: $0,
                count: unsafeData.count / MemoryLayout<Element>.stride
            ))
        }
#endif  // swift(>=5.0)
    }
}

//Extension for the above method.
//extension Data {
//    /// Creates a new buffer by copying the buffer pointer of the given array.
//    ///
//    /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
//    /// for bit with no indirection or reference-counting operations; otherwise, reinterpreting
//    /// data from the resulting buffer has undefined behavior.
//    /// - Parameter array: An array with elements of type `T`.
//    init<T>(copyingBufferOf array: [T]) {
//        self = array.withUnsafeBufferPointer(Data.init)
//    }
//}
//
//extension Array {
//    /// Creates a new array from the bytes of the given unsafe data.
//    ///
//    /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
//    /// with no indirection or reference-counting operations; otherwise, copying the raw bytes in
//    /// the `unsafeData`'s buffer to a new array returns an unsafe copy.
//    /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
//    /// `MemoryLayout<Element>.stride`.
//    /// - Parameter unsafeData: The data containing the bytes to turn into an array.
//    init?(unsafeData: Data) {
//        guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
//        
//        // Calculate the number of elements in the array
//        let count = unsafeData.count / MemoryLayout<Element>.stride
//
//        // Create a new array with the right count and initialize with the raw bytes
//        self.init()
//
//        // Now you can fill the array with the actual data
//        let pointer = unsafeData.withUnsafeBytes { (rawBufferPointer) -> UnsafePointer<Element> in
//            return rawBufferPointer.baseAddress!.assumingMemoryBound(to: Element.self)
//        }
//
//        // Initialize the array with the correct number of elements
//        self = Array(UnsafeBufferPointer(start: pointer, count: count))
//    }
//}
