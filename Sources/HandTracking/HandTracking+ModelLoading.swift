import RealityKit
import ARKit

public extension HandTracking {
    /// Loads a 3D model and attaches it to the right hand entity
    /// - Parameters:
    ///   - modelName: The name of the model to load (without file extension)
    ///   - completion: Optional completion handler that provides the loaded entity
    func loadModelForRightHand(modelName: String, completion: ((Entity?) -> Void)? = nil) {
        Task { @MainActor in
            do {
                print("📦 Attempting to load model: \(modelName)")
                
                // Try to load the model from the main bundle
                if let entity = try? Entity.load(named: modelName) {
                    print("✅ Successfully loaded model: \(modelName)")
                    attachModelToRightHand(entity)
                    completion?(entity)
                    return
                }
                
                print("❌ Failed to load model: \(modelName)")
                completion?(nil)
            }
        }
    }
    
    /// Loads a 3D model from a URL and attaches it to the right hand entity
    /// - Parameters:
    ///   - url: The URL of the model to load
    ///   - completion: Optional completion handler that provides the loaded entity
    func loadModelForRightHand(from url: URL, completion: ((Entity?) -> Void)? = nil) {
        Task { @MainActor in
            do {
                let entity = try ModelEntity.load(contentsOf: url)
                if let modelEntity = entity as? ModelEntity {
                    attachModelToRightHand(modelEntity)
                    completion?(modelEntity)
                } else {
                    print("Failed to load model as ModelEntity from URL")
                    completion?(nil)
                }
            } catch {
                print("Failed to load model from URL: \(error)")
                completion?(nil)
            }
        }
    }
    
    /// Removes any currently attached model from the right hand
    func removeModelFromRightHand() {
        Task { @MainActor in
            // Remove all child entities that are ModelEntity instances
            rightHandEntity.children.forEach { child in
                if child is ModelEntity {
                    child.removeFromParent()
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func attachModelToRightHand(_ modelEntity: ModelEntity) {
        Task { @MainActor in
            // Remove any existing model
            removeModelFromRightHand()
            
            // Add the new model
            rightHandEntity.addChild(modelEntity)
            
            // Center the model on the hand
            modelEntity.position = .zero
            
            // Add collision component
            modelEntity.components.set(CollisionComponent(shapes: [.generateBox(size: modelEntity.visualBounds(relativeTo: nil).extents)], mode: .trigger))
            
            // Add tool collision trigger component
            let trigger = ToolCollisionTriggerComponent(
                totalStages: 1,
                stageDescriptions: ["Ready for interaction"]
            )
            modelEntity.toolCollisionTrigger = trigger
        }
    }
} 