import RealityKit
import Combine

// MARK: - Entity Extensions
extension Entity {
    var toolInteractionTarget: ToolInteractionTargetComponent? {
        get { components[ToolInteractionTargetComponent.self] }
        set { components[ToolInteractionTargetComponent.self] = newValue }
    }
    
    var collisionSubscription: CollisionSubscriptionComponent? {
        get { components[CollisionSubscriptionComponent.self] }
        set { components[CollisionSubscriptionComponent.self] = newValue }
    }
    
    var toolCollisionTrigger: ToolCollisionTriggerComponent? {
        get { components[ToolCollisionTriggerComponent.self] }
        set { components[ToolCollisionTriggerComponent.self] = newValue }
    }
    
    private func handleCollision(_ event: CollisionEvents.Began) {
        print("💥 Collision detected between: \(event.entityA.name) and \(event.entityB.name)")
        
        // Check if this entity is involved in the collision
        guard event.entityA == self || event.entityB == self else {
            return
        }
        
        guard let targetComponent = self.toolInteractionTarget,
              let toolTrigger = event.entityA.toolCollisionTrigger ?? event.entityB.toolCollisionTrigger,
              targetComponent.matchesCurrentStage(of: toolTrigger) else {
            return
        }
        
        print("✅ Valid collision detected")
        
        var trigger = toolTrigger
        // Trigger the interaction
        if trigger.progressToNextStage() {
            // Update the tool's trigger
            if let toolEntity = event.entityA as? ModelEntity ?? event.entityB as? ModelEntity {
                toolEntity.toolCollisionTrigger = trigger
            }
            
            // Mark this target as completed
            var updatedComponent = targetComponent
            updatedComponent.complete()
            self.toolInteractionTarget = updatedComponent
            
            // Call the completion handler
            targetComponent.onInteraction?()
            print("🎯 Interaction completed")
        }
    }
}

// MARK: - Collision Groups
public extension CollisionGroup {
    static let tool = CollisionGroup(rawValue: 1 << 0)
    static let interactionTarget = CollisionGroup(rawValue: 1 << 1)
}

// MARK: - Public Entity Extensions
public extension Entity {
    /// Sets up a tool interaction target with proper collision handling
    func setupToolInteractionTarget(stage: Int, 
                                  interactionData: [String: Any]? = nil,
                                  collisionGroup: CollisionGroup = .interactionTarget,
                                  collisionMask: CollisionGroup = .tool,
                                  onInteraction: (() -> Void)? = nil) {
        
        print("🔧 Setting up tool interaction target")
        
        components.remove(PhysicsBodyComponent.self)
        components.remove(CollisionSubscriptionComponent.self)
        
        // Create and set the interaction target component
        let targetComponent = ToolInteractionTargetComponent(
            targetStage: stage,
            interactionData: interactionData,
            collisionGroup: collisionGroup,
            collisionMask: collisionMask,
            onInteraction: onInteraction
        )
        self.toolInteractionTarget = targetComponent
        
        // Get the actual bounds of the model
        let bounds = self.visualBounds(relativeTo: nil)
        
        // Add collision component using the model's actual bounds
        let collisionComponent = CollisionComponent(
            shapes: [.generateBox(size: bounds.extents)],
            mode: .trigger,
            filter: CollisionFilter(
                group: targetComponent.collisionGroup,
                mask: targetComponent.collisionMask
            )
        )
        components.set(collisionComponent)
        
        // Add physics body using the same bounds
        let physicsBody = PhysicsBodyComponent(
            shapes: [.generateBox(size: bounds.extents)],
            mass: 0,
            mode: .static
        )
        components.set(physicsBody)
        
        // Set up collision subscription when added to scene
        if let scene = self.scene {
            print("📡 Setting up collision subscription")
            let subscription = scene.subscribe(to: CollisionEvents.Began.self) { [weak self] event in
                self?.handleCollision(event)
            }
            self.collisionSubscription = CollisionSubscriptionComponent(subscription: subscription)
        } else {
            print("⚠️ No scene available for collision subscription")
        }
    }
} 
