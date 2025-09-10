//
//  MyDetectObjectApp.swift
//  MyDetectObject
//
//  Created by paxcreation on 13/11/2024.
//

import SwiftUI
import Combine


public class DetectObjectSDK: ObservableObject {
    public static let shared = DetectObjectSDK()
    
    public var objectDetectionHelper = ObjectDetectionHelper()

    @Published public var isActive: Bool = false
    public var onEvent: (([String: Any]) -> Void)?
    
    // Store file paths
    public private(set) var modelPath: String?
    public private(set) var textPath: URL?

    private init() {}

    /// Start SDK with event callback
    public func start(modelPath: String, textPath: URL, onEvent: @escaping ([String: Any]) -> Void) {
            self.modelPath = modelPath
            self.textPath = textPath
            self.onEvent = onEvent
            self.isActive = true
            objectDetectionHelper.setup()
            
        }

    /// Send event to host app
    public func sendEvent(_ payload: [String: Any]) {
        onEvent?(payload)
    }

    /// Finish SDK
    public func finish() {
            objectDetectionHelper.close()
            self.isActive = false
            self.onEvent = nil
            self.modelPath = nil
            self.textPath = nil
        }
}



//@main //Starting Point of app.
//struct MyDetectObjectApp: App {
//    var body: some Scene { //App Body declared. This has some UI environments.
//        WindowGroup { //Main UI content. Primary UI view.
//            ContentView();
//        }
//    }
//}
