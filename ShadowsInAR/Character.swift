/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This class manages the main character, including its animations, sounds and direction.
*/

import SceneKit


func planeIntersect(planeNormal: SIMD3<Float>, planeDist: Float, rayOrigin: SIMD3<Float>, rayDirection: SIMD3<Float>) -> Float {
    return (planeDist - simd_dot(planeNormal, rayOrigin)) / simd_dot(planeNormal, rayDirection)
}


class Character: NSObject {
 
    static private let speedFactor: CGFloat = 2
    static private let stepsCount = 10
    
    var initialPosition = SIMD3<Float>(0, 0, 0)
    
    // some constants
    static private let gravity = Float(0.004)
    static private let jumpImpulse = Float(0.1)
    static private let minAltitude = Float(-10)
    static private let enableFootStepSound = true
    static private let collisionMargin = Float(0.04)
    static private let modelOffset = SIMD3<Float>(0, -collisionMargin, 0)
    static private let collisionMeshBitMask = 8
    
    
    // Character handle
    var characterNode: SCNNode! // top level node
    private var characterOrientation: SCNNode! // the node to rotate to orient the character
    private var model: SCNNode! // the model loaded from the character file
    
    // Physics
    private var characterCollisionShape: SCNPhysicsShape?
    private var collisionShapeOffsetFromModel = SIMD3<Float>.zero
    private var downwardAcceleration: Float = 0
    
    // Jump
    private var controllerJump: Bool = false
    private var jumpState: Int = 0
    var groundNode: SCNNode?
    private var groundNodeLastPosition = SIMD3<Float>.zero
    var baseAltitude: Float = 0
    private var targetAltitude: Float = 0
    
    // Void playing the step sound too often
    private var lastStepFrame: Int = 0
    private var frameCounter: Int = 0
    
    // Direction
    private var previousUpdateTime: TimeInterval = 0
    private var controllerDirection = SIMD2<Float>.zero
    
    // States
    private var attackCount: Int = 0
    private var lastHitTime: TimeInterval = 0
    
    private var shouldResetCharacterPosition = false
    
    // Particle systems
    private var jumpDustParticle: SCNParticleSystem!
    private var fireEmitter: SCNParticleSystem!
    private var smokeEmitter: SCNParticleSystem!
    private var whiteSmokeEmitter: SCNParticleSystem!
    private var spinParticle: SCNParticleSystem!
    private var spinCircleParticle: SCNParticleSystem!
    
    private var spinParticleAttach: SCNNode!
    
    private var fireEmitterBirthRate: CGFloat = 0.0
    private var smokeEmitterBirthRate: CGFloat = 0.0
    private var whiteSmokeEmitterBirthRate: CGFloat = 0.0
    
    // Sound effects
    private var aahSound: SCNAudioSource!
    private var ouchSound: SCNAudioSource!
    private var hitSound: SCNAudioSource!
    private var hitEnemySound: SCNAudioSource!
    private var explodeEnemySound: SCNAudioSource!
    private var catchFireSound: SCNAudioSource!
    private var jumpSound: SCNAudioSource!
    private var attackSound: SCNAudioSource!
    private var steps = [SCNAudioSource](repeating: SCNAudioSource(), count: Character.stepsCount )
    
    private(set) var offsetedMark: SCNNode?
    
    // Actions
    var isJump: Bool = false
    var direction = SIMD2<Float>()
    var physicsWorld: SCNPhysicsWorld?
    
    // MARK: - Initialization
    
    init(scene: SCNScene) {
        super.init()
        
        loadCharacter()
        loadParticles()
        loadSounds()
        loadAnimations()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    
    func loadCharacter() {
        /// Load character from external file
        let scene = SCNScene( named: "art.scnassets/character/max.scn")!
        model = scene.rootNode.childNode( withName: "Max_rootNode", recursively: true)
        model.simdPosition = Character.modelOffset
        model.scale = SCNVector3(0.7, 0.7, 0.7)
        model.castsShadow = true
        
        /* setup character hierarchy
         character
         |_orientationNode
         |_model
         */
        characterNode = SCNNode()
        characterNode.name = "character"
        characterNode.simdPosition = initialPosition
        characterNode.castsShadow = false
        
        characterOrientation = SCNNode()
        characterNode.addChildNode(characterOrientation)
        characterOrientation.addChildNode(model)
        
        let collider = model.childNode(withName: "collider", recursively: true)!
        collider.physicsBody = SCNPhysicsBody(type: .kinematic, shape: characterCollisionShape)
        collider.castsShadow = false
        collider.physicsBody?.categoryBitMask = BitmaskPlayer
        collider.physicsBody?.contactTestBitMask = BitmaskWall | BitmaskBall
      
        // Setup collision shape
        let (min, max) = model.boundingBox
        let collisionCapsuleRadius = CGFloat(max.x - min.x) * CGFloat(0.4)
        let collisionCapsuleHeight = CGFloat(max.y - min.y)
        
        let collisionGeometry = SCNCapsule(capRadius: collisionCapsuleRadius, height: collisionCapsuleHeight)
        characterCollisionShape = SCNPhysicsShape(geometry: collisionGeometry, options:[.collisionMargin: Character.collisionMargin])
        collisionShapeOffsetFromModel = SIMD3<Float>(0, Float(collisionCapsuleHeight) * 0.51, 0.0)
    }
    
    
    
    private func loadParticles() {
        var particleScene = SCNScene( named: "art.scnassets/character/jump_dust.scn")!
        
        particleScene = SCNScene(named:"art.scnassets/particles/particles_spin.scn")!
        spinParticle = (particleScene.rootNode.childNode(withName: "particles_spin", recursively: true)?.particleSystems?.first!)!
        spinCircleParticle = (particleScene.rootNode.childNode(withName: "particles_spin_circle", recursively: true)?.particleSystems?.first!)!
        
        spinParticleAttach = model.childNode(withName: "particles_spin_circle", recursively: true)
    }
    
    private func loadSounds() {
        aahSound = SCNAudioSource( named: "audio/aah_extinction.mp3")!
        aahSound.volume = 1.0
        aahSound.isPositional = false
        aahSound.load()
        
        ouchSound = SCNAudioSource(named: "audio/ouch_firehit.mp3")!
        ouchSound.volume = 2.0
        ouchSound.isPositional = false
        ouchSound.load()
        
        hitSound = SCNAudioSource(named: "audio/hit.mp3")!
        hitSound.volume = 2.0
        hitSound.isPositional = false
        hitSound.load()
        
        hitEnemySound = SCNAudioSource(named: "audio/Explosion1.m4a")!
        hitEnemySound.volume = 2.0
        hitEnemySound.isPositional = false
        hitEnemySound.load()
        
        explodeEnemySound = SCNAudioSource(named: "audio/Explosion2.m4a")!
        explodeEnemySound.volume = 2.0
        explodeEnemySound.isPositional = false
        explodeEnemySound.load()
        
        jumpSound = SCNAudioSource(named: "audio/jump.m4a")!
        jumpSound.volume = 0.2
        jumpSound.isPositional = false
        jumpSound.load()
        
        attackSound = SCNAudioSource(named: "audio/attack.mp3")!
        attackSound.volume = 1.0
        attackSound.isPositional = false
        attackSound.load()
        
        for i in 0..<Character.stepsCount {
            steps[i] = SCNAudioSource(named: "audio/Step_rock_0\(UInt32(i)).mp3")!
            steps[i].volume = 0.5
            steps[i].isPositional = false
            steps[i].load()
        }
    }
    
    private func loadAnimations() {
        
        let idleAnimation = Character.loadAnimation(fromSceneNamed: "art.scnassets/character/max_idle.scn")
        model.addAnimationPlayer(idleAnimation, forKey: "idle")
        idleAnimation.play()
        
        let walkAnimation = Character.loadAnimation(fromSceneNamed: "art.scnassets/character/max_walk.scn")
        walkAnimation.speed = Character.speedFactor
        walkAnimation.stop()
        
        if Character.enableFootStepSound {
            walkAnimation.animation.animationEvents = [
                SCNAnimationEvent(keyTime: 0.1, block: { _, _, _ in self.playFootStep() }),
                SCNAnimationEvent(keyTime: 0.6, block: { _, _, _ in self.playFootStep() })
            ]
        }
        model.addAnimationPlayer(walkAnimation, forKey: "walk")
        
        let jumpAnimation = Character.loadAnimation(fromSceneNamed: "art.scnassets/character/max_jump.scn")
        jumpAnimation.animation.isRemovedOnCompletion = false
        jumpAnimation.stop()
        jumpAnimation.animation.animationEvents = [SCNAnimationEvent(keyTime: 0, block: { _, _, _ in self.playJumpSound() })]
        model.addAnimationPlayer(jumpAnimation, forKey: "jump")
        
        let spinAnimation = Character.loadAnimation(fromSceneNamed: "art.scnassets/character/max_spin.scn")
        spinAnimation.animation.isRemovedOnCompletion = false
        spinAnimation.speed = 1.5
        spinAnimation.stop()
        spinAnimation.animation.animationEvents = [SCNAnimationEvent(keyTime: 0, block: { _, _, _ in self.playAttackSound() })]
        model!.addAnimationPlayer(spinAnimation, forKey: "spin")
    }
    
    
    
    var node: SCNNode! {
        return characterNode
    }
    
    func queueResetCharacterPosition() {
        shouldResetCharacterPosition = true
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // MARK: - Audio
    
    func playFootStep() {
        if groundNode != nil && isWalking { // We are in the air, no sound to play.
            //            if isWalking { // We are in the air, no sound to play.
            // Play a random step sound.
            let randSnd: Int = Int(Float(arc4random()) / Float(RAND_MAX) * Float(Character.stepsCount))
            let stepSoundIndex: Int = min(Character.stepsCount - 1, randSnd)
            characterNode.runAction(SCNAction.playAudio( steps[stepSoundIndex], waitForCompletion: false))
        }
    }
    
    func playJumpSound() {
        characterNode!.runAction(SCNAction.playAudio(jumpSound, waitForCompletion: false))
    }
    
    func playAttackSound() {
        characterNode!.runAction(SCNAction.playAudio(attackSound, waitForCompletion: false))
    }
    
    
    // MARK: - Controlling the character
    
    private var directionAngle: CGFloat = 0.0 {
        didSet {
            characterOrientation.runAction(
                SCNAction.rotateTo(x: 0.0, y: directionAngle, z: 0.0, duration: 0.1, usesShortestUnitArc:true))
            
        }
        
    }
    
    func update(atTime time: TimeInterval, with renderer: SCNSceneRenderer) {
        frameCounter += 1
        
        if shouldResetCharacterPosition {
            shouldResetCharacterPosition = false
            resetCharacterPosition()
            return
        }
        
        var characterVelocity = SIMD3<Float>.zero
        
        // setup
        var groundMove = SIMD3<Float>.zero
        
        
        // did the ground moved?
        if groundNode != nil {
            let groundPosition = groundNode!.simdWorldPosition
            
            groundMove = groundPosition - groundNodeLastPosition
        }
        
        characterVelocity = SIMD3<Float>(groundMove.x, 0, groundMove.z)
        
        let direction = characterDirection(withPointOfView:renderer.pointOfView)
        
        if previousUpdateTime == 0.0 {
            previousUpdateTime = time
        }
        
        
        let deltaTime = time - previousUpdateTime
        let characterSpeed = CGFloat(deltaTime) * Character.speedFactor * walkSpeed
        
        let virtualFrameCount = Int(deltaTime / (1 / 60.0))
        previousUpdateTime = time
        
        // move
        if direction != SIMD3<Float>(0,0,0) {
            characterVelocity = direction * Float(characterSpeed)
            
            
            walkSpeed = CGFloat(simd_length(direction))
            
            // move character
            directionAngle = CGFloat(atan2f(direction.x, direction.z))
            
            isWalking = true
        } else {
            isWalking = false
        }
        
        // put the character on the ground
        let up = SIMD3<Float>(0, 1, 0)
        var wPosition = characterNode.simdWorldPosition
        
        
        // gravity
        downwardAcceleration -= Character.gravity
        wPosition.y += downwardAcceleration
        let HIT_RANGE = Float(0.2)
        var p0 = wPosition
        var p1 = wPosition
        p0.y = wPosition.y + up.y * HIT_RANGE
        p1.y = wPosition.y - up.y * HIT_RANGE
        
        //        let options: [String: Any] = [
        //            SCNHitTestOption.backFaceCulling.rawValue: false,
        //            SCNHitTestOption.categoryBitMask.rawValue: Character.collisionMeshBitMask,
        //            SCNHitTestOption.ignoreHiddenNodes.rawValue: false]
        
        let hitFrom = SCNVector3(p0)
        let hitTo = SCNVector3(p1)
        //        let hitResult = renderer.scene!.rootNode.hitTestWithSegment(from: hitFrom, to: hitTo, options: options).first
        //
        let hitResult = renderer.scene!.physicsWorld.rayTestWithSegment(from: hitFrom, to: hitTo, options: [.collisionBitMask: BitmaskWall, .searchMode: SCNPhysicsWorld.TestSearchMode.closest, .backfaceCulling: false]).first
        
        let wasTouchingTheGroup = groundNode != nil
        groundNode = nil
        var touchesTheGround = false
        
        
        if let hit = hitResult {
            let ground = SIMD3<Float>(hit.worldCoordinates)
            if wPosition.y <= ground.y + Character.collisionMargin {
                wPosition.y = ground.y + Character.collisionMargin
                if downwardAcceleration < 0 {
                    downwardAcceleration = 0
                }
                groundNode = hit.node
                touchesTheGround = true
                
            }
        } else {
            if wPosition.y < Character.minAltitude {
                wPosition.y = Character.minAltitude
                //reset
                queueResetCharacterPosition()
            }
        }
        
        groundNodeLastPosition = (groundNode != nil) ? groundNode!.simdWorldPosition: SIMD3<Float>.zero
        
        
        //jump
        if jumpState == 0 {
            if isJump && touchesTheGround {
                downwardAcceleration += Character.jumpImpulse
                jumpState = 1
                
                model.animationPlayer(forKey: "jump")?.play()
            }
        } else {
            if jumpState == 1 && !isJump {
                jumpState = 2
            }
            
            if downwardAcceleration > 0 {
                for _ in 0..<virtualFrameCount {
                    downwardAcceleration *= jumpState == 1 ? 0.99: 0.2
                }
            }
            
            if touchesTheGround {
                if !wasTouchingTheGroup {
                    model.animationPlayer(forKey: "jump")?.stop(withBlendOutDuration: 0.1)
                    
                    
                }
                
                if !isJump {
                    jumpState = 0
                }
            }
        }
        
        if touchesTheGround && !wasTouchingTheGroup && lastStepFrame < frameCounter - 10 {
            // sound
            lastStepFrame = frameCounter
            characterNode.runAction(SCNAction.playAudio(steps[0], waitForCompletion: false))
        }
        
        if wPosition.y < characterNode.simdPosition.y {
            wPosition.y = characterNode.simdPosition.y
        }
        
        // progressively update the elevation node when we touch the ground
        if touchesTheGround {
            targetAltitude = wPosition.y
        }
        baseAltitude *= 0.95
        baseAltitude += targetAltitude * 0.05
        
        characterVelocity.y += downwardAcceleration
        if simd_length_squared(characterVelocity) > 10E-4 * 10E-4 {
            let startPosition = characterNode!.presentation.simdWorldPosition + collisionShapeOffsetFromModel
            slideInWorld(fromPosition: startPosition, velocity: characterVelocity)
        }
        //
    }
    // MARK: - Animating the character
    
    var isAttacking: Bool {
        return attackCount > 0
    }
    
    func attack() {

        attackCount += 1
        model.animationPlayer(forKey: "spin")?.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.attackCount -= 1
        }
        spinParticleAttach.addParticleSystem(spinCircleParticle)

    }
    
    var isWalking: Bool = false {
        didSet {
            if oldValue != isWalking {
                if isWalking {
                    model.animationPlayer(forKey: "walk")?.play()
                } else {
                    model.animationPlayer(forKey: "walk")?.stop(withBlendOutDuration: 0.2)
                }
            }
        }
    }
    
    var walkSpeed: CGFloat = 1.0 {
        didSet {
            model.animationPlayer(forKey: "walk")?.speed = Character.speedFactor * walkSpeed
        }
    }
    
    
    func characterDirection(withPointOfView pointOfView: SCNNode?) -> SIMD3<Float> {
        let controllerDir = self.direction
        if controllerDir == SIMD2<Float>(0,0) {
            return SIMD3<Float>.zero
        }
        
        var directionWorld = SIMD3<Float>.zero
        if let pov = pointOfView {
            let p1 = pov.presentation.simdConvertPosition(SIMD3<Float>(controllerDir.x, 0.0, controllerDir.y), to: nil)
            let p0 = pov.presentation.simdConvertPosition(SIMD3<Float>.zero, to: nil)
            directionWorld = p1 - p0
            directionWorld.y = 0
            if simd_any(directionWorld != SIMD3<Float>.zero) {
                let minControllerSpeedFactor = Float(0.2)
                let maxControllerSpeedFactor = Float(1.0)
                let speed = simd_length(controllerDir) * (maxControllerSpeedFactor - minControllerSpeedFactor) + minControllerSpeedFactor
                directionWorld = speed * simd_normalize(directionWorld)
            }
        }
        
        return directionWorld
        
    }
    

    
    func resetCharacterPosition() {
        characterNode.opacity = 0.0
        characterNode.simdPosition = initialPosition

        let resetAnimation = SCNAction.repeat(SCNAction.sequence([
            SCNAction.fadeOpacity(to: 0.01, duration: 0.1),
            SCNAction.fadeOpacity(to: 1.0, duration: 0.1)
            ]), count: 3)
        
        node.runAction(resetAnimation)
        
        downwardAcceleration = 0
    }
    
    // MARK: utils
    
    class func loadAnimation(fromSceneNamed sceneName: String) -> SCNAnimationPlayer {
        let scene = SCNScene( named: sceneName )!
        // find top level animation
        var animationPlayer: SCNAnimationPlayer! = nil
        scene.rootNode.enumerateChildNodes { (child, stop) in
            if !child.animationKeys.isEmpty {
                animationPlayer = child.animationPlayer(forKey: child.animationKeys[0])
                stop.pointee = true
            }
        }
        return animationPlayer
    }
    
    // MARK: - physics contact
    func slideInWorld(fromPosition start: SIMD3<Float>, velocity: SIMD3<Float>) {
        
        DispatchQueue.main.async { [self] in
            let maxSlideIteration: Int = 4
            var iteration = 0
            var stop: Bool = false
            
            var replacementPoint = start
            
            var start = start
            var velocity = velocity
            let options: [SCNPhysicsWorld.TestOption: Any] = [
                SCNPhysicsWorld.TestOption.collisionBitMask: BitmaskWall,
                SCNPhysicsWorld.TestOption.searchMode: SCNPhysicsWorld.TestSearchMode.closest]
            while !stop {
                var from = matrix_identity_float4x4
                from.position = start
                
                var to: matrix_float4x4 = matrix_identity_float4x4
                to.position = start + velocity
                
                let contacts = physicsWorld!.convexSweepTest(
                    with: characterCollisionShape!,
                    from: SCNMatrix4(from),
                    to: SCNMatrix4(to),
                    options: options)
                if !contacts.isEmpty {
                    (velocity, start) = handleSlidingAtContact(contacts.first!, position: start, velocity: velocity)
                    iteration += 1
                    
                    if simd_length_squared(velocity) <= (10E-3 * 10E-3) || iteration >= maxSlideIteration {
                        replacementPoint = start
                        stop = true
                    }
                } else {
                    replacementPoint = start + velocity
                    stop = true
                }
            }
            characterNode!.simdWorldPosition = replacementPoint - collisionShapeOffsetFromModel
        }
    }
    
    private func handleSlidingAtContact(_ closestContact: SCNPhysicsContact, position start: SIMD3<Float>, velocity: SIMD3<Float>)
    -> (computedVelocity: simd_float3, colliderPositionAtContact: simd_float3) {
        let originalDistance: Float = simd_length(velocity)
        
        let colliderPositionAtContact = start + Float(closestContact.sweepTestFraction) * velocity
        
        // Compute the sliding plane.
        let slidePlaneNormal = SIMD3<Float>(closestContact.contactNormal)
        let slidePlaneOrigin = SIMD3<Float>(closestContact.contactPoint)
        let centerOffset = slidePlaneOrigin - colliderPositionAtContact
        
        // Compute destination relative to the point of contact.
        let destinationPoint = slidePlaneOrigin + velocity
        
        // We now project the destination point onto the sliding plane.
        let distPlane = simd_dot(slidePlaneOrigin, slidePlaneNormal)
        
        // Project on plane.
        var t = planeIntersect(planeNormal: slidePlaneNormal, planeDist: distPlane,
                               rayOrigin: destinationPoint, rayDirection: slidePlaneNormal)
        
        let normalizedVelocity = velocity * (1.0 / originalDistance)
        let angle = simd_dot(slidePlaneNormal, normalizedVelocity)
        
        var frictionCoeff: Float = 0.3
        if abs(angle) < 0.9 {
            t += 10E-3
            frictionCoeff = 1.0
        }
        let newDestinationPoint = (destinationPoint + t * slidePlaneNormal) - centerOffset
        
        // Advance start position to nearest point without collision.
        let computedVelocity = frictionCoeff * Float(1.0 - closestContact.sweepTestFraction)
        * originalDistance * simd_normalize(newDestinationPoint - start)
        
        return (computedVelocity, colliderPositionAtContact)
    }

    
}






