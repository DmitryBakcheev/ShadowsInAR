//
//  ConvinientExtensions.swift
//  ShadowsInAR
//
//  Created by Dmitry Bakcheev on 12/10/23.
//

import UIKit
import CoreGraphics
import SceneKit
import simd

extension simd_float2 {
    static let zero = simd_float2(0.0, 0.0)
    
    func allZero() -> Bool {
        return x == 0 && y == 0
    }
    static func ==(left: simd_float2, right: simd_float2) -> simd_int2 {
        return simd_int2(left.x == right.x ? -1: 0, left.y == right.y ? -1: 0)
    }
}

extension simd_float3 {
    static let zero = simd_float3(0.0, 0.0, 0.0)
    
    func allZero() -> Bool {
        return x == 0 && y == 0 && z == 0
    }
    
    static func ==(left: simd_float3, right: simd_float3) -> simd_int3 {
        return simd_int3(left.x == right.x ? -1: 0, left.y == right.y ? -1: 0, left.z == right.z ? -1: 0)
    }
    static func !=(left: simd_float3, right: simd_float3) -> simd_int3 {
        return simd_int3(left.x != right.x ? -1: 0, left.y != right.y ? -1: 0, left.z != right.z ? -1: 0)
    }
}

extension simd_float4 {
    static let zero = simd_float4(0.0, 0.0, 0.0, 0.0)
    
    static func ==(left: simd_float4, right: simd_float4) -> simd_int4 {
        return simd_int4(left.x == right.x ? -1: 0, left.y == right.y ? -1: 0, left.z == right.z ? -1: 0, left.w == right.w ? -1: 0)
    }
    var xyz: simd_float3 {
        get {
            return simd_float3(x, y, z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
}

extension simd_float4x4 {
    var position: simd_float3 {
        get {
            return columns.3.xyz
        }
        set {
            columns.3.xyz = newValue
        }
    }
}


extension FloatingPoint {
  var degreesToRadians: Self { return self * .pi / 180 }
  var radiansToDegrees: Self { return self * 180 / .pi }
}

extension UIView {
  public func addConstraintsWithFormat(_ format: String, views: UIView...) {
    
    var viewsDictionary = [String: UIView]()
    for (index, view) in views.enumerated() {
      let key = "v\(index)"
      viewsDictionary[key] = view
      view.translatesAutoresizingMaskIntoConstraints = false
    }
    
      addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
  }
  
  public func fillSuperview() {
    translatesAutoresizingMaskIntoConstraints = false
    if let superview = superview {
      leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
      rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
      topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
      bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
    }
  }
  
  public func anchor(_ top: NSLayoutYAxisAnchor? = nil, left: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, right: NSLayoutXAxisAnchor? = nil, topConstant: CGFloat = 0, leftConstant: CGFloat = 0, bottomConstant: CGFloat = 0, rightConstant: CGFloat = 0, widthConstant: CGFloat = 0, heightConstant: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    
    _ = anchorWithReturnAnchors(top, left: left, bottom: bottom, right: right, topConstant: topConstant, leftConstant: leftConstant, bottomConstant: bottomConstant, rightConstant: rightConstant, widthConstant: widthConstant, heightConstant: heightConstant)
  }
  
  public func anchorWithReturnAnchors(_ top: NSLayoutYAxisAnchor? = nil, left: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, right: NSLayoutXAxisAnchor? = nil, topConstant: CGFloat = 0, leftConstant: CGFloat = 0, bottomConstant: CGFloat = 0, rightConstant: CGFloat = 0, widthConstant: CGFloat = 0, heightConstant: CGFloat = 0) -> [NSLayoutConstraint] {
    translatesAutoresizingMaskIntoConstraints = false
    
    var anchors = [NSLayoutConstraint]()
    
    if let top = top {
      anchors.append(topAnchor.constraint(equalTo: top, constant: topConstant))
    }
    
    if let left = left {
      anchors.append(leftAnchor.constraint(equalTo: left, constant: leftConstant))
    }
    
    if let bottom = bottom {
      anchors.append(bottomAnchor.constraint(equalTo: bottom, constant: -bottomConstant))
    }
    
    if let right = right {
      anchors.append(rightAnchor.constraint(equalTo: right, constant: -rightConstant))
    }
    
    if widthConstant > 0 {
      anchors.append(widthAnchor.constraint(equalToConstant: widthConstant))
    }
    
    if heightConstant > 0 {
      anchors.append(heightAnchor.constraint(equalToConstant: heightConstant))
    }
    
    anchors.forEach({$0.isActive = true})
    
    return anchors
  }
  
  public func anchorCenterXToSuperview(constant: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    if let anchor = superview?.centerXAnchor {
      centerXAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
    }
  }
  
  public func anchorCenterYToSuperview(constant: CGFloat = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    if let anchor = superview?.centerYAnchor {
      centerYAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
    }
  }
  
  public func anchorCenterSuperview() {
    anchorCenterXToSuperview()
    anchorCenterYToSuperview()
  }
}

struct ScreenSize {
  static let width        = UIScreen.main.bounds.size.width
  static let height       = UIScreen.main.bounds.size.height
  static let maxLength    = max(ScreenSize.width, ScreenSize.height)
  static let minLength    = min(ScreenSize.width, ScreenSize.height)
  static let size         = CGSize(width: ScreenSize.width, height: ScreenSize.height)
}

struct DeviceType {
  static let isiPhone4OrLess = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength < 568.0
  static let isiPhone5 = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 568.0
  static let isiPhone6 = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 667.0
  static let isiPhone6Plus = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 736.0
  static let isiPhoneX = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.maxLength == 812.0
  static let isiPad = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.maxLength == 1024.0
  static let isiPadPro = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.maxLength == 1366.0
}

extension SCNNode {
  func size() -> (width: Float, height: Float, lenght: Float) {
    let (localMin, localMax) = self.boundingBox
    let min = self.convertPosition(localMin, to: nil)
    let max = self.convertPosition(localMax, to: nil)
    
    let width = max.x - min.x
    let height = max.y - min.y
    let lenght =  max.z - min.z
    
    return (width, height, lenght)
  }
}


extension SCNPhysicsContact {
    
    
    func match(_ category: Int, block:(_ matching:SCNNode, _ other: SCNNode) -> Void ) {
        if self.nodeA.physicsBody?.categoryBitMask == category {
            block(self.nodeA, self.nodeB)
        }
        if self.nodeB.physicsBody?.categoryBitMask == category {
            block(self.nodeB, self.nodeA)
        }
    }
}


