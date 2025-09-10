//
//  ObjectDetectState.swift
//  MyDetectObject
//
//  Created by paxcreation on 13/11/2024.
//

import Foundation
import SceneKit

//class ObjectDetectState: ObservableObject {
//    @Published var bjectDetect: [ObjectDetect] = []
//}

class ObjectDetect { // Represent detected objects using this.
//    var boundingBoxes: CGRect = CGRect() // Creates an empty rectangle. Has two main components - Origin(Bottom-left corner), Size(width, height)
//    // CGRect(x: 0, y: 0, width: 100, height: 50) represents a rectangle starting at (0, 0) with a width of 100 and a height of 50.
    var left: Float = 0
    var right: Float = 0
    var top: Float = 0
    var bottom: Float = 0
    var crop: String? = ""
    var w: Float = 0
    var h: Float = 0
    var boundingBoxes: CGRect = CGRect()
    var worldPositionBox: BoundingBox3D = BoundingBox3D(min: SCNVector3(), max: SCNVector3())
    var label: String = ""
    var name: String = ""
    var conf: Float = 0
    var shelf = -1
    var bay = -1
    var facing = -1
}
