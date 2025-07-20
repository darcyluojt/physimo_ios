//
//  ImagePropertyOrientation.swift
//  physimo
//
//  Created by Darcy LUO on 20/07/2025.
//

import Foundation
import UIKit       // for UIImage.Orientation
import ImageIO     // for CGImagePropertyOrientation

//extension CGImagePropertyOrientation {
//  init(_ uiOrientation: UIImage.Orientation) {
//    switch uiOrientation {
//      case .up:            self = .up
//      case .down:          self = .down
//      case .left:          self = .left
//      case .right:         self = .right
//      case .upMirrored:    self = .upMirrored
//      case .downMirrored:  self = .downMirrored
//      case .leftMirrored:  self = .leftMirrored
//      case .rightMirrored: self = .rightMirrored
//      @unknown default:    self = .up
//    }
//  }
//}


extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
            @unknown default: self = .up
        }
    }
}
extension UIImage.Orientation {
    init(_ cgOrientation: UIImage.Orientation) {
        switch cgOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
            @unknown default: self = .up
        }
    }
}
