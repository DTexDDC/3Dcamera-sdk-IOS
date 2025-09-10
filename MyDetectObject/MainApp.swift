//
//  MainApp.swift
//  MyDetectObject
//
//  Created by Surya on 5/9/2025.
//
import SwiftUI

@main
struct HostApp: App {
    var body: some Scene {
        WindowGroup {
            HostContentView() // Your host app’s main content
        }
    }
}

struct HostContentView: View {
    @StateObject var sdk = DetectObjectSDK.shared

    var body: some View {
            VStack {
                Text("Main App Home")
                    .font(.title)

                Button("Launch SDK") {
                    let file1 = "/path/to/file1.tflite"   // Have a proper file path from the ios device.
                    let file2 = "/path/to/file2.txt"
                    
                    // Ignore the commented code below as I used it to test without apis.
//                    guard let file1URL = copyFileFromBundleToDevice(fileName: "output_float32", fileExtension: "tflite") else {
//                        print("Failed to load model")
//                        return
//                    }
//                    let file1 = file1URL.path()
//                    
//                    guard let file2URL = copyFileFromBundleToDevice(fileName: "output_float32_labels", fileExtension: "txt") else {
//                        print("Failed to load model")
//                        return
//                    }
//                    let file2 = file2URL.path()

                    sdk.start(modelPath: file1, textPath: URL(fileURLWithPath: file2)) { payload in
//                        print("📩 Received SDK event: \(payload)")
                        // Complete this by adding code to get data when sent.
                        if let name = payload["type"] as? String {
                            if (name == "finished") {
                                sdk.finish()
                                print("Finished")
                            } else if (name == "Detections") {
                                let overviewImage = payload["overviewImage"]
                                if let detections = payload["objects"] as? [[String: Any]] {
                                    for detection in detections {
                                        let bay = detection["bay"]
                                        let facing = detection["facing"]
                                        let shelf = detection["shelf"]
                                        let label = detection["label"]
                                        let score = detection["score"]
                                        let crop = detection["crop"]
                                        let labelDisplay = detection["labelDisplay"]
                                        let x = detection["centreX"]
                                        let y = detection["centreY"]
                                        let z = detection["centreZ"]
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $sdk.isActive) {
                ContentView()
                    .environmentObject(sdk.objectDetectionHelper) // inject into child views
                                .onAppear {
                                    print("SDK Root Appeared")
                                }
                                .onDisappear {
                                    sdk.finish()
                                }
            }
        }
}

func copyFileFromBundleToDevice(fileName: String, fileExtension: String) -> URL? {
    let fileManager = FileManager.default
    
    // 1. Get the file URL from the app bundle
    guard let bundleURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
        print("File \(fileName).\(fileExtension) not found in bundle")
        return nil
    }
    
    // 2. Destination URL in Documents directory
    let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let destinationURL = docsURL.appendingPathComponent(bundleURL.lastPathComponent)
    
    do {
        // Remove existing file if present
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        // Copy file from bundle to Documents
        try fileManager.copyItem(at: bundleURL, to: destinationURL)
        print("File copied to:", destinationURL.path)
        return destinationURL
    } catch {
        print("Error copying file:", error)
        return nil
    }
}

