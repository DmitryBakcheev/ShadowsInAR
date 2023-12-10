//
//  Overlay.swift
//  ShadowsInAR
//
//  Created by Dmitry Bakcheev on 12/10/23.
//

import SpriteKit

class Overlay: SKScene {
    private var overlayNode: SKNode
    private var congratulationsGroupNode: SKNode?
    private var collectedKeySprite: SKSpriteNode!
    private var collectedGemsSprites = [SKSpriteNode]()
    public var controlOverlay: ControlOverlay?


// MARK: - Initialization
    init(size: CGSize, controller: ViewController) {
        overlayNode = SKNode()
        super.init(size: size)
        
        let w: CGFloat = size.width
        let h: CGFloat = size.height
        
        // Setup the game overlays using SpriteKit.
        scaleMode = .resizeFill
        
        addChild(overlayNode)
        overlayNode.position = CGPoint(x: 0.0, y: h)
        
        
        // The virtual D-pad
        controlOverlay = ControlOverlay(frame: CGRect(x: CGFloat(0), y: CGFloat(0), width: w, height: h))
        controlOverlay!.leftPad.delegate = controller
        controlOverlay!.buttonA.delegate = controller
        controlOverlay!.buttonB.delegate = controller
        controlOverlay!.buttonC.delegate = controller
            addChild(controlOverlay!)
   

        // Assign the SpriteKit overlay to the SceneKit view.
        isUserInteractionEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    func showVirtualPad() {
        controlOverlay!.isHidden = false
    }
    
    func hideVirtualPad() {
        controlOverlay!.isHidden = true
    }
  

}

