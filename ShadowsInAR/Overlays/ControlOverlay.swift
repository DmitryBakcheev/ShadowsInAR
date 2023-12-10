//
//  ControlOverlay.swift
//  ShadowsInAR
//
//  Created by Dmitry Bakcheev on 12/10/23.
//

import SpriteKit

class ControlOverlay: SKNode {
    
    let buttonMargin = CGFloat( 25 )
    
    var leftPad = PadOverlay()
    var buttonA = ButtonOverlay("A")
    var buttonB = ButtonOverlay("B")
    var buttonC = ButtonOverlay("C")

    init(frame: CGRect) {
        super.init()
        
        leftPad.position = CGPoint(x: CGFloat(20), y: CGFloat(70))
        addChild(leftPad)

        buttonB.position = CGPoint(x: frame.size.width - 70, y: 70)
        addChild(buttonB)
        
        
        let buttonDistance = buttonB.size.height / CGFloat( 2 ) + buttonMargin + buttonB.size.height / CGFloat( 2 )
        let center = CGPoint( x: buttonB.position.x + buttonB.size.width / 2.0, y: buttonB.position.y + buttonB.size.height / 2.0 )
        
        
        let buttonAx = center.x - buttonDistance * CGFloat(cosf(Float.pi / 2.0)) - (buttonB.size.width / 2)
        let buttonAy = center.y + buttonDistance * CGFloat(sinf(Float.pi / 2.0)) - (buttonB.size.height / 2)
        buttonA.position = CGPoint(x: buttonAx, y: buttonAy)
        addChild(buttonA)
    

        let buttonCx = center.x - buttonDistance * CGFloat(cosf(Float.pi / 6.0)) - (buttonB.size.width / 2)
        let buttonCy = center.y + buttonDistance * CGFloat(sinf(Float.pi / 6.0)) - (buttonB.size.height / 2)
        buttonC.position = CGPoint(x: buttonCx, y: buttonCy)
        addChild(buttonC)
        
    }

    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
