//
//  ViewController.swift
//  ShadowsInAR
//
//  Created by Dmitry Bakcheev on 12/10/23.
//

import UIKit
import SceneKit
import ARKit


//  global bitmask variables
let BitmaskPlayer = 2
let BitmaskWall = 128


class ViewController: UIViewController, SCNSceneRendererDelegate & SCNPhysicsContactDelegate
{
    

    // Overlays
    var overlay: Overlay?
    
    // Character
    var character: Character?
    
    //  Lights (spot or directional)
    var lightNode: Light?
    
    // Focus point
    private var focusPoint: CGPoint!
    private var focusNode: SCNNode!
    private var isFocusActive = true
    
    
    // Update delta time
    var lastUpdateTime = TimeInterval()
    
    
    // Other
    var sceneRenderer: SCNSceneRenderer?
    var gameWorldCenterTransform: SCNMatrix4 = SCNMatrix4Identity
    var isRenderingActive = true
    
    
    let arscnView: ARSCNView = {
        let view = ARSCNView()
        view.showsStatistics = true
        return view
    }()
    
    
    lazy var startButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8)
        button.setTitle("Choose starting point and hit the button", for: .normal)
        button.tintColor = .black
        button.frame = CGRect(x: 150, y: 150, width: 50, height: 50)
        button.layer.cornerRadius = button.frame.width / 2
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(startGame), for: .touchUpInside)
        button.isHidden = false
        return button
    }()
    
    lazy var spotlightButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8)
        button.setTitle("Spot", for: .normal)
        button.tintColor = .black
        button.frame = CGRect(x: 150, y: 150, width: 50, height: 50)
        button.layer.cornerRadius = button.frame.width / 2
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(switchLight), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    lazy var directionalLightButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8)
        button.setTitle("Directional", for: .normal)
        button.tintColor = .black
        button.frame = CGRect(x: 150, y: 150, width: 50, height: 50)
        button.layer.cornerRadius = button.frame.width / 2
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(switchLight), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    

    
    //    MARK: - viewDidLoad
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneRenderer = arscnView
        sceneRenderer!.delegate = self
        
        initScene()
        initARSession()
        addFocusNode()
        
        arscnView.automaticallyUpdatesLighting = false
        arscnView.autoenablesDefaultLighting = true
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupARSCNView()
        setupARSCNViewSubviews()
        overlay = Overlay(size: view.bounds.size, controller: self)
        arscnView.overlaySKScene = overlay
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    
    //  MARK: - Setup Scene
    
    func setupARSCNView() {
        view.addSubview(arscnView)
        arscnView.fillSuperview()
        
    }
    
    
    func setupARSCNViewSubviews() {
        
        arscnView.addSubview(startButton)
        startButton.anchor(arscnView.safeAreaLayoutGuide.topAnchor, left: arscnView.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: arscnView.safeAreaLayoutGuide.rightAnchor, topConstant: 10, leftConstant: 10, bottomConstant: 0, rightConstant: 10, widthConstant: 0, heightConstant: 80)
        
        arscnView.addSubview(directionalLightButton)
        directionalLightButton.anchor(arscnView.safeAreaLayoutGuide.topAnchor, left: arscnView.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: arscnView.safeAreaLayoutGuide.rightAnchor, topConstant: 10, leftConstant: 10, bottomConstant: 0, rightConstant: 200, widthConstant: 0, heightConstant: 80)
       
        arscnView.addSubview(spotlightButton)
        spotlightButton.anchor(arscnView.safeAreaLayoutGuide.topAnchor, left: arscnView.safeAreaLayoutGuide.leftAnchor, bottom: nil, right: arscnView.safeAreaLayoutGuide.rightAnchor, topConstant: 10, leftConstant: 200, bottomConstant: 0, rightConstant: 10, widthConstant: 0, heightConstant: 80)
        
    }
    
    
    func initScene() {
        let scene = SCNScene()
        scene.isPaused = false
        arscnView.scene = scene
    }
    
    
    func initARSession() {
        arscnView.delegate = self
        focusPoint = CGPoint(x: view.center.x,
                             y: view.center.y + view.center.y * 0.25)
        
        guard ARWorldTrackingConfiguration.isSupported else { return }
        
        let config = ARWorldTrackingConfiguration()
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        } else {
        //      Handle device that doesn't support scene reconstruction
        }
        //      Enable physics visualization for debugging
        arscnView.debugOptions = [.showPhysicsShapes, .showLightExtents, .showLightInfluences]
        
        config.isLightEstimationEnabled = true
        config.worldAlignment = .gravity
        config.providesAudioData = false
        config.planeDetection = .horizontal
        arscnView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        arscnView.scene.physicsWorld.contactDelegate = self
    }
    
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    
    
    // MARK: - Focus Node
    
    func addFocusNode(){
        let focusScene = SCNScene(named: "art.scnassets/Models/FocusScene.scn")!
        focusNode = focusScene.rootNode.childNode(withName: "focus", recursively: false)!
        arscnView.scene.rootNode.addChildNode(focusNode)
        focusNode.isHidden = false
    }
    
    
    func updateFocusNode() {
        
        guard let raycastQuery = arscnView.raycastQuery(from: self.focusPoint,
                                                        allowing: .existingPlaneGeometry,
                                                        alignment: .horizontal),
        let raycastResult = arscnView.session.raycast(raycastQuery).first else { return }
        let position = SCNVector3(raycastResult.worldTransform.columns.3.x,
                                  raycastResult.worldTransform.columns.3.y + 0.01,
                                  raycastResult.worldTransform.columns.3.z)
        self.focusNode.position = position
        
    }
    
    
    
    //     MARK: - Game management
    
    
    func setupCharacter() {
        character = Character(scene: arscnView.scene)
        character?.node.position = SCNVector3(gameWorldCenterTransform.m41,
                                              gameWorldCenterTransform.m42,
                                              gameWorldCenterTransform.m43)
        character?.initialPosition = (character?.node.simdPosition)!
        character!.physicsWorld = arscnView.scene.physicsWorld
        arscnView.scene.rootNode.addChildNode(character!.node!)
        
    }
    
    
    func setupLights() {
        lightNode = Light()
        lightNode?.position = SCNVector3Make(-0.005, 0.01, -0.022)
        arscnView.pointOfView?.addChildNode(lightNode!)  
    }
    
    
    @objc func switchLight(sender: UIButton) {
        arscnView.debugOptions = [.showPhysicsShapes, .showLightExtents, .showLightInfluences]
        if sender.titleLabel?.text == "Spot" {
            lightNode?.light = lightNode?.spotLight()
        } else {
            lightNode?.light = lightNode?.directionalLight()
        }
    }
    
    
    @objc func startGame() {
        startButton.isHidden = true
        focusNode.removeFromParentNode()
        
        gameWorldCenterTransform = focusNode.transform
        setupCharacter()
        setupLights()
        isFocusActive = false
        isRenderingActive = false
        directionalLightButton.isHidden = false
        spotlightButton.isHidden = false
    }
    
    
    //    character and focus nodes
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        updateFocusNode()
        character?.update(atTime: time, with: renderer)
        
    }
    
}
