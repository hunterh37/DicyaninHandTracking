import RealityKit
import ARKit

public extension DicyaninHandTracking {
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
    
    // MARK: - Private Methods
    
    private func attachModelToRightHand(_ entity: Entity) {
        Task { @MainActor in
            // Remove any existing model
//            removeModelFromRightHand()
 
            // Store reference to new entity
            currentToolEntity = entity
            
            // Add the new model
            rightHandEntity.addChild(entity)
            
            // Center the model on the hand
            entity.position = .zero
            
            // Add collision component
            entity.components.set(CollisionComponent(shapes: [.generateBox(size: entity.visualBounds(relativeTo: nil).extents)], mode: .trigger))
            
            entity.components.set(InputTargetComponent())
            
            // Add tool collision trigger component
            let trigger = ToolCollisionTriggerComponent(
                totalStages: 1,
                stageDescriptions: ["Ready for interaction"]
            )
            entity.toolCollisionTrigger = trigger
        }
    }
} 
