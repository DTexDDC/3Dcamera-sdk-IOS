//
//  sdkSendData.swift
//  MyDetectObject
//
//  Created by Surya on 8/9/2025.
//

import SwiftUI

class sdkSendData {
    
    static func send(binding: [ObjectDetect], overviewImage: CVPixelBuffer?) {
        var shelf: [ObjectDetect] = []
        var bay: [ObjectDetect] = []
        var labels: [ObjectDetect] = []
        var products: [ObjectDetect] = []
        
        for obj in binding {
            if (obj.name == "end_point") {
                bay.append(obj)
                continue
            } else if (obj.name == "label") {
                labels.append(obj)
                continue
            } else if (obj.name == "shelf") {
                shelf.append(obj)
                continue
            }
            products.append(obj)
        }
        
        shelf.sort {$0.bottom < $1.bottom}
        bay.sort {$0.left < $1.left}
        
        products.sort {$0.top <= $1.top }
        var pos = 0
        for i in 0..<shelf.count {
            if (pos >= products.count) {
                break
            }
            while true {
                if (products[pos].top > shelf[i].top && products[pos].top < shelf[i+1].top) {
                    products[pos].shelf = i+1
                    pos += 1
                } else {
                    break
                }
            }
        }
        
        products.sort {$0.left <= $1.left}
        pos = 0
        if (bay.count >= 2) {
            for i in stride(from: 1, to: bay.count, by: 2) {
                if (pos >= products.count) {
                    break
                }
                var facing = 0
                while true {
                    if (products[pos].left > bay[i-1].left && products[pos].left < bay[i].left) {
                        products[pos].bay = i+1
                        products[pos].facing = facing+1
                        facing += 1
                    }
                }
                facing = 0
            }
        }
        
        var detectionPayload: [[String: Any]] = []

        for obj in products {
            let dict: [String: Any] = [
                "bay": obj.bay,
                "facing": obj.facing,
                "shelf": obj.shelf,
                "label": obj.name,
                "crop": obj.crop ?? "",
                "score": obj.conf,
                "labelDisplay": obj.label,
                "centreX": obj.worldPositionBox.max.x,
                "centreY": obj.worldPositionBox.max.y,
                "centreZ": obj.worldPositionBox.max.z
            ]
            detectionPayload.append(dict)
        }
        var image: String = ""
        if let pbImage = overviewImage {
            image = cropPixelBufferToBase64(pixelBuffer: pbImage, x: 0, y: 0, width: 640, height: 640)!
        } else {
            print("sceneImage is nil!")
        }
        
        let payload: [String: Any] = [
            "type": "Detections",
            "overviewImage": image,
            "objects": detectionPayload
        ]
        DetectObjectSDK.shared.sendEvent(payload)
        
    }
}
