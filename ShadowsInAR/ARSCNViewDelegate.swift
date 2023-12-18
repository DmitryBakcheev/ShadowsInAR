//
//  ARSCNViewDelegate.swift
//  ShadowsInAR
//
//  Created by Dmitry Bakcheev on 12/10/23.
//

import ARKit

extension ViewController : ARSCNViewDelegate {
    
    
    func createGeometryFromAnchor(meshAnchor: ARMeshAnchor) -> SCNGeometry {
        
        let meshGeometry = meshAnchor.geometry
        let vertices = meshGeometry.vertices
        let normals = meshGeometry.normals
        let faces = meshGeometry.faces
        
        // use the MTL buffer that ARKit gives us
        let vertexSource = SCNGeometrySource(buffer: vertices.buffer, vertexFormat: vertices.format, semantic: .vertex, vertexCount: vertices.count, dataOffset: vertices.offset, dataStride: vertices.stride)
        
        let normalsSource = SCNGeometrySource(buffer: normals.buffer, vertexFormat: normals.format, semantic: .normal, vertexCount: normals.count, dataOffset: normals.offset, dataStride: normals.stride)
        
        // copy bytes as we may use them later
        let faceData = Data(bytes: faces.buffer.contents(), count: faces.buffer.length)
        
        // create the geometry element
        let geometryElement = SCNGeometryElement(data: faceData, primitiveType: toSCNGeometryPrimitiveType(faces.primitiveType), primitiveCount: faces.count, bytesPerIndex: faces.bytesPerIndex)
        
        let geometry = SCNGeometry(sources: [vertexSource, normalsSource], elements: [geometryElement])
        
        let defaultMaterial = SCNMaterial()
        defaultMaterial.lightingModel = .shadowOnly
        

//        defaultMaterial.diffuse.contents = UIColor.gray
//        defaultMaterial.colorBufferWriteMask = [.alpha]
//        defaultMaterial.colorBufferWriteMask   = SCNColorMask(rawValue: 0)
//        defaultMaterial.lightingModel = .constant
        defaultMaterial.writesToDepthBuffer = true
//        defaultMaterial.isDoubleSided = true
//        defaultMaterial.isLitPerPixel = true
//
        geometry.materials = [defaultMaterial]
        
        return geometry
    }
    
    
    func toSCNGeometryPrimitiveType(_ ar: ARGeometryPrimitiveType) -> SCNGeometryPrimitiveType {
        switch ar {
        case .line: return .line
        case .triangle: return .triangles
        default: fatalError("Unknown type")
        }
    }
    
    
    
    // MARK: - Rendering
    

    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if let meshAnchor = anchor as? ARMeshAnchor {
            
            let geometry = createGeometryFromAnchor(meshAnchor: meshAnchor)
            node.geometry = geometry
//            geometry.firstMaterial?.colorBufferWriteMask = [.alpha]
            geometry.firstMaterial?.lightingModel = .shadowOnly

            node.renderingOrder = -1
            
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        if isRenderingActive {
            
            if let meshAnchor = anchor as? ARMeshAnchor {
                let geometry = createGeometryFromAnchor(meshAnchor: meshAnchor)
                node.geometry = geometry
//            geometry.firstMaterial?.colorBufferWriteMask = [.alpha]

                node.name = "wall"
                node.physicsBody = SCNPhysicsBody.static()
                node.castsShadow = false
                node.physicsBody?.categoryBitMask = BitmaskWall
                node.physicsBody!.physicsShape = SCNPhysicsShape(geometry: geometry, options: [.type: SCNPhysicsShape.ShapeType.concavePolyhedron, .keepAsCompound: SCNPhysicsShape.ShapeType.concavePolyhedron])
                node.renderingOrder = -1
                
                
            }
        }
    }
    
}

