//
//  VCExtensionForOverlays.swift
//  ShadowsInAR
//
//  Created by Dmitry Bakcheev on 12/10/23.
//


import ARKit
import UIKit

extension ViewController: PadOverlayDelegate & ButtonOverlayDelegate {
    // MARK: - PadOverlayDelegate
    
    
    func padOverlayVirtualStickInteractionDidStart(_ padNode: PadOverlay) {
        if padNode == overlay!.controlOverlay!.leftPad {
            characterDirection = SIMD2<Float>(Float(padNode.stickPosition.x), -Float(padNode.stickPosition.y))
        }
    }
    
    
    func padOverlayVirtualStickInteractionDidChange(_ padNode: PadOverlay) {
        if padNode == overlay!.controlOverlay!.leftPad {
            characterDirection = SIMD2<Float>(Float(padNode.stickPosition.x), -Float(padNode.stickPosition.y))
            
        }
    }
    
    
    func padOverlayVirtualStickInteractionDidEnd(_ padNode: PadOverlay) {
        if padNode == overlay!.controlOverlay!.leftPad {
            characterDirection = [0, 0]
        }
    }
    
    
    func willPress(_ button: ButtonOverlay) {
        if button == overlay!.controlOverlay!.buttonA {
            controllerJump(true)
        }
        if button == overlay!.controlOverlay!.buttonB {
            controllerAttack()
        }
        if button == overlay!.controlOverlay!.buttonC {
            controllerReset()
        }
    }
    
    
    func didPress(_ button: ButtonOverlay) {
        if button == overlay!.controlOverlay!.buttonA {
            controllerJump(false)
        }
    }
    
    
    
    // MARK: - Controlling the character
    
    
    func controllerJump(_ controllerJump: Bool) {
        character!.isJump = controllerJump
    }
    
    
    func controllerAttack() {
        if !self.character!.isAttacking {
            self.character!.attack()
        }
    }
    
    
    func controllerReset() {
        character?.resetCharacterPosition()
    }
    
    
    var characterDirection: vector_float2 {
        get {
            return character!.direction
        }
        set {
            var direction = newValue
            let l = simd_length(direction)
            if l > 1.0 {
                direction *= 1 / l
            }
            character!.direction = direction
        }
    }
}
