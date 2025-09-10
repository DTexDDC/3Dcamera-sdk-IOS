//
//  StartStopView.swift
//  MyDetectObject
//
//  Created by Surya on 22/1/2025.
//

import UIKit
import SwiftUI

struct StartStopRepresentable: UIViewRepresentable {
    
    @Binding var showCamera: Bool
    
    func makeUIView(context: Context) -> StartStopView {
        let view = StartStopView()
        view.onShowCameraChange = { newValue in
            showCamera = newValue // Update the SwiftUI Binding
        }
        return view
    }
    
    func updateUIView(_ uiView: StartStopView, context: Context) {
        if uiView.showCamera != showCamera {
            showCamera = uiView.showCamera
        }
    }
}

class StartStopView: UIView {
    
    @IBOutlet private weak var startStopView: UIView!
    @IBOutlet private weak var circleView: UIView!
    @IBOutlet private weak var circleButton: UIButton!
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    
    @StateObject var sdk = DetectObjectSDK.shared
    
    var onShowCameraChange: ((Bool) -> Void)? // Closure to handle state changes
            var showCamera: Bool = false {
            didSet {
                onShowCameraChange?(showCamera)
            }
        }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customInit()
    }
    
    private func customInit() {
        let bundle = Bundle.main
        let nibName = String(describing: StartStopView.self)
        bundle.loadNibNamed(nibName, owner: self, options: nil)
        addSubview(startStopView)
//        startStopView.frame = bounds
//        startStopView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        circleButton.clipsToBounds = true
//        circleView.backgroundColor = .white
//        circleView.layer.borderColor = UIColor.white.cgColor
//        circleView.layer.borderWidth = 5
////        circleButton.translatesAutoresizingMaskIntoConstraints = true
        
        // Make the button square
            circleButton.setTitle("Start", for: .normal)
            circleButton.setTitleColor(.white, for: .normal)
            circleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            circleButton.layer.cornerRadius = 15   // slight rounding for square look
            circleButton.clipsToBounds = true

            // Optional: fix width & height (square shape)
        circleButton.frame = startStopView.bounds
        circleButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//            circleButton.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                circleButton.widthAnchor.constraint(equalToConstant: 100),
//                circleButton.heightAnchor.constraint(equalToConstant: 100)
//            ])
        
        // Make buttons curved
//        configureButtonAppearance(startButton)
//        configureButtonAppearance(stopButton)
    }
    
    @IBAction func circleButtonHandler(btn: UIButton) {
        if showCamera == false {
//            UIButton.animate(withDuration: 0.5) {
//                print("Video on")
//                btn.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
//                btn.layer.cornerRadius = 0
//                self.showCamera = true
//            }
            // Start
                    showCamera = true
                    btn.setTitle("Pause", for: .normal)
                    btn.backgroundColor = .systemRed
                    print("Video on")
        } else if showCamera == true {
            // Pause
                    showCamera = false
                    btn.setTitle("Start", for: .normal)
                    btn.backgroundColor = .systemBlue
                    print("Video off")

                    // Example: send reset payload
                    sdk.sendEvent([
                        "labelDisplay": "0",
                        "score": 0,
                        "centreX": 0,
                        "centreY": 0,
                        "centreZ": 0,
                        "facing": 0,
                        "shelf": 0,
                        "bay": 0,
                        "cropString": 0
                    ])
//            UIButton.animate(withDuration: 0.5) {
//                btn.transform = CGAffineTransform(scaleX: 1, y: 1)
//                btn.layer.cornerRadius = 40
//                self.showCamera = false
//            }
        }
    }

    private func configureButtonAppearance(_ button: UIButton) {
        button.layer.cornerRadius = button.bounds.height / 2 // Fully rounded if height equals width
        button.layer.masksToBounds = true // Clips the button content to the bounds
    }
    
    @IBAction func startButtonHandler(btn: UIButton) {
        print("Start")
        showCamera = true
    }
    
    @IBAction func stopButtonHandler(btn: UIButton) {
        print("Stop")
        showCamera = false
    }



}
