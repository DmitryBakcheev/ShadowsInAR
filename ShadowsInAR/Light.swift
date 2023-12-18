//
//  Lights.swift
//  ShadowsInAR
//
//  Created by Dmitry Bakcheev on 12/10/23.
//

import SceneKit


class Light: SCNNode {
    
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    

    func spotLight() -> SCNLight {
        let light                           = SCNLight()
        
        light.type                          = .spot
        light.castsShadow                   = true
        light.color                         = UIColor.white
        light.shadowColor                   = UIColor.black
        
        light.shadowMode                    = .forward
        light.shadowRadius                  = 20
        //        light.shadowCascadeCount            = 3
        //        light.shadowCascadeSplittingFactor  = 0.09
        //        light.shadowBias                    = 0.1
        light.shadowSampleCount             = 64 // (the smaller the value, the better the performance)
        light.automaticallyAdjustsShadowProjection = true
        //        light.sampleDistributedShadowMaps = true
        light.shadowMapSize = CGSize(width: 2048, height: 2048)
        
        light.spotInnerAngle = 10
        light.spotOuterAngle = 30
        light.intensity = 30
        light.zNear = 0.01
        light.zFar = 2
        
        return light
    }
    
    
    func directionalLight() -> SCNLight {
        
        let light                           = SCNLight()
        light.type                          = .directional
        light.castsShadow                   = true
        light.color                         = UIColor.white
        light.shadowColor                   = UIColor(red: 1, green: 0, blue: 0, alpha: 0.9)
        light.shadowMode                    = .modulated
        light.shadowRadius                  = 20
        light.shadowCascadeCount            = 3
        light.shadowCascadeSplittingFactor  = 0.09
        light.shadowBias                    = 0.1
        light.shadowSampleCount             = 64 // (the smaller the value, the better the performance)
        light.shadowMapSize = CGSize(width: 2048, height: 2048)
        
        
        
        return light
        
    }
}
