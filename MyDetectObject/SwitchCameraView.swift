//
//  SwitchCameraView.swift
//  MyDetectObject
//
//  Created by Surya on 20/1/2025.
//

import UIKit
import SwiftUI

struct SwitchCameraRepresentable: UIViewRepresentable {
    var onStop: () -> Void
    var onStart: () -> Void
    
    func makeUIView(context: Context) -> SwitchCameraView {
        let view = SwitchCameraView()
        view.onStop = onStop
        view.onStart = onStart
        return view
    }
    
    func updateUIView(_ uiView: SwitchCameraView, context: Context) {
        
    }
}

enum ZoomState {
    case ultrawide
    case standard
//    case telephoto
}

protocol SwitchCameraViewDelegate: AnyObject {
    func switchZoomTapped(state: ZoomState)
}

class SwitchCameraView: UIView {
    @IBOutlet private weak var  switchView: UIView!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var ultrawideButton: UIButton!
    @IBOutlet private weak var standardButton: UIButton!
//    @IBOutlet private weak var telephotoButton: UIButton!
    
    var onStart: (() -> Void)?
    var onStop: (() -> Void)?
    
    private var zoomState = ZoomState.standard
    
    private var selectedButton: UIButton?
    
    weak var delegate: SwitchCameraViewDelegate?
    
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
        let nibName = String(describing: SwitchCameraView.self)
        bundle.loadNibNamed(nibName, owner: self, options: nil)
        addSubview(switchView)
        switchView.frame = bounds
        switchView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        standardButton.isHidden = false
        standardButton.isEnabled = true
//        telephotoButton.isHidden = false
//        telephotoButton.isEnabled = true
        
//        standardButton.setTitleColor(UIColor.yellow, for: .normal)
//        selectedButton = standardButton
    }
    
    @IBAction func ultrawideButtonHandler(btn: UIButton) {
        onStop?()
//        selectedButton?.setTitleColor(UIColor.red, for: .normal)
//        zoomState = .ultrawide
//        ultrawideButton.setTitleColor(UIColor.yellow, for: .normal)
//        selectedButton = ultrawideButton
//        delegate?.switchZoomTapped(state: zoomState)
    }
    
    @IBAction func standardButtonHandler(btn: UIButton) {
        onStart?()
//        onStop?()
//        selectedButton?.setTitleColor(UIColor.red, for: .normal)
//        zoomState = .standard
//        standardButton.setTitleColor(UIColor.yellow, for: .normal)
//        selectedButton = standardButton
//        delegate?.switchZoomTapped(state: zoomState)
        
    }
    
//    @IBAction func telephotoButtonHandler(btn: UIButton) {
//        selectedButton?.setTitleColor(UIColor.red, for: .normal)
//        zoomState = .telephoto
//        telephotoButton.setTitleColor(UIColor.yellow, for: .normal)
//        selectedButton = telephotoButton
//        delegate?.switchZoomTapped(state: zoomState)
//        
//    }
    
    func hideUltrawideButton() {
        ultrawideButton.isHidden = true
    }
    
//    func hideTelephotoButton() {
//        telephotoButton.isHidden = true
//    }
    
    func configureforPortraitOrientation() {
        stackView.axis = .horizontal
    }

}
