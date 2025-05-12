import RealityKit
import Combine

/// A component that stores the collision subscription
struct CollisionSubscriptionComponent: Component {
    var subscription: Cancellable?
    var sceneSubscription: Cancellable?
}

/// A component that defines an object that can trigger interactions with hand-held tools
struct ToolInteractionTargetComponent: Component {
    /// The stage this target triggers
    let targetStage: Int
    
    /// Whether this interaction has been completed
    var isCompleted: Bool = false
    
    /// Additional data needed for the interaction
    var interactionData: [String: Any]?
    
    /// The collision group this target belongs to
    let collisionGroup: CollisionGroup
    
    /// The collision mask for detecting collisions
    let collisionMask: CollisionGroup
    
    /// Completion handler called when interaction occurs
    var onInteraction: (() -> Void)?
    
    init(targetStage: Int, 
         interactionData: [String: Any]? = nil,
         collisionGroup: CollisionGroup = .default,
         collisionMask: CollisionGroup = .default,
         onInteraction: (() -> Void)? = nil) {
        self.targetStage = targetStage
        self.interactionData = interactionData
        self.collisionGroup = collisionGroup
        self.collisionMask = collisionMask
        self.onInteraction = onInteraction
    }
    
    /// Check if this target matches the current stage of a tool
    func matchesCurrentStage(of trigger: ToolCollisionTriggerComponent) -> Bool {
        guard trigger.currentStage == targetStage,
              !isCompleted else {
            return false
        }
        return true
    }
    
    /// Mark this interaction as completed
    mutating func complete() {
        isCompleted = true
    }
}

/// A component that defines collision triggers for tool interactions
struct ToolCollisionTriggerComponent: Component {
    /// The current stage of the interaction
    var currentStage: Int = 0
    
    /// The total number of stages for this interaction
    let totalStages: Int
    
    /// Description of what needs to be done in this stage
    let stageDescriptions: [String]
    
    /// Whether this trigger has been completed
    var isCompleted: Bool = false
    
    init(totalStages: Int, stageDescriptions: [String]) {
        self.totalStages = totalStages
        self.stageDescriptions = stageDescriptions
    }
    
    /// Progress to the next stage
    mutating func progressToNextStage() -> Bool {
        if currentStage >= totalStages - 1 {
            isCompleted = true
            return true  // Return true for the final stage
        }
        currentStage += 1
        return true
    }
    
    /// Get the current stage description
    var currentStageDescription: String {
        guard currentStage < stageDescriptions.count else { return "Unknown stage" }
        return stageDescriptions[currentStage]
    }
}

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
        
        // Add collision component
        let collisionComponent = CollisionComponent(
            shapes: [.generateBox(size: .init(repeating: 0.1))],
            mode: .trigger,
            filter: CollisionFilter(
                group: targetComponent.collisionGroup,
                mask: targetComponent.collisionMask
            )
        )
        components.set(collisionComponent)
        
        // Add physics body for collision detection
        let physicsBody = PhysicsBodyComponent(
            shapes: [.generateBox(size: .init(repeating: 0.1))],
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
extension CollisionGroup {
    static let tool = CollisionGroup(rawValue: 1 << 0)
    static let interactionTarget = CollisionGroup(rawValue: 1 << 1)
} 
