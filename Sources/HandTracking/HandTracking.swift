//
//  HandTracking.swift
//  HandTracking
//
//  Created by Hunter Harris on 5/11/25.
//

import RealityKit
import ARKit
import SwiftUI

/// Protocol defining the interface for hand tracking functionality
public protocol HandTrackingProtocol: ObservableObject {
    var latestHandTracking: HandAnchorUpdate { get }
    var isRightHanded: Bool { get set }
    var controlRootEntity: Entity { get }
    
    func start(showHandVisualizations: Bool) async
    func stop()
    func highlightFinger(_ finger: HandSkeleton.JointName, hand: HandType, duration: TimeInterval?, isActive: Bool)
    func setFingerActive(_ finger: HandSkeleton.JointName, onHand isLeftHand: Bool, isActive: Bool)
    func setAllFingersActive(_ isActive: Bool, duration: TimeInterval?, addCollision: Bool)
}

var rootEntity = Entity()
var rightHandEntity = Entity()
var leftHandEntity = Entity()

/// Main class implementing hand tracking functionality
public class HandTracking: HandTrackingProtocol {
    // MARK: - Properties
    private var session = ARKitSession()
    private var handTracking = HandTrackingProvider()
    
    @Published public var latestHandTracking: HandAnchorUpdate = .init(left: nil, right: nil)
    @Published public var isRightHanded = true
    
    // MARK: - Entity Management
    private var leftFingerVisualizationEntities: [HandSkeleton.JointName: FingerVisualizationEntity] = [:]
    private var rightFingerVisualizationEntities: [HandSkeleton.JointName: FingerVisualizationEntity] = [:]
    
    public let controlRootEntity = Entity()
    
    /// Registers all required components and systems for hand tracking
    public static func registerComponents() {
        // Register interaction components
        ToolInteractionTargetComponent.registerComponent()
        ToolCollisionTriggerComponent.registerComponent()
        CollisionSubscriptionComponent.registerComponent()
    }
    
    // MARK: - Hand Joints
    private let handJoints: [HandSkeleton.JointName] = [
        .indexFingerTip, .middleFingerTip, .littleFingerTip, .ringFingerTip, .wrist,
        .littleFingerKnuckle, .littleFingerMetacarpal, .littleFingerIntermediateBase,
        .ringFingerKnuckle, .ringFingerMetacarpal, .ringFingerIntermediateBase,
        .middleFingerKnuckle, .middleFingerMetacarpal, .middleFingerIntermediateBase,
        .indexFingerKnuckle, .indexFingerMetacarpal, .indexFingerIntermediateBase,
        .thumbKnuckle, .thumbIntermediateBase, .thumbTip, .thumbIntermediateTip
    ]
    
    // MARK: - Initialization
    public init() {
    }
    
    // MARK: - Public Methods
    public func start(showHandVisualizations: Bool = true) async {
        Task { @MainActor in
            rightHandEntity.removeFromParent()
            leftHandEntity.removeFromParent()
            rightHandEntity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.2)], mode: .trigger))
            rightHandEntity.components.set(PhysicsBodyComponent(shapes: [.generateSphere(radius: 0.2)], mass: 10, mode: .kinematic))
            
            rootEntity.addChild(rightHandEntity)
            rootEntity.addChild(leftHandEntity)
            
            if showHandVisualizations {
                initializeVisualizationFingerTips()
            }
            
            await initializeHandTracking()
        }
    }
    
    public func stop() {
        session.stop()
        removeAllHandEntities()
    }
    
    public func highlightFinger(_ finger: HandSkeleton.JointName, hand: HandType, duration: TimeInterval? = nil, isActive: Bool = true) {
        let isRightHand = hand == .rightHand
        let visualizationEntities = isRightHand ? rightFingerVisualizationEntities : leftFingerVisualizationEntities
        
        guard let entity = visualizationEntities[finger] else { return }
        entity.setIsActiveVisual(isActive, removeAfter: duration)
    }
    
    public func setFingerActive(_ finger: HandSkeleton.JointName, onHand isLeftHand: Bool, isActive: Bool) {
        let visualizationEntities = isLeftHand ? leftFingerVisualizationEntities : rightFingerVisualizationEntities
        guard let entity = visualizationEntities[finger] else { return }
        entity.setIsActiveVisual(isActive)
    }
    
    /// Sets all finger entities to active or inactive
    /// - Parameters:
    ///   - isActive: Whether to make the entities visible
    ///   - duration: Optional duration after which to revert the state
    ///   - addCollision: Whether to add collision components
    public func setAllFingersActive(_ isActive: Bool, duration: TimeInterval? = nil, addCollision: Bool = false) {
        // Set left hand fingers
        for (_, entity) in leftFingerVisualizationEntities {
            entity.setIsActiveVisual(isActive, removeAfter: duration, addCollision: addCollision)
        }
        
        // Set right hand fingers
        for (_, entity) in rightFingerVisualizationEntities {
            entity.setIsActiveVisual(isActive, removeAfter: duration, addCollision: addCollision)
        }
    }
    
    // MARK: - Private Methods
    private func initializeHandTracking() async {
        do {
            guard HandTrackingProvider.isSupported else { return }
            handTracking = HandTrackingProvider()
            try await session.run([handTracking])
            await publishHandTrackingUpdates()
        } catch {
            print("Failed to initialize hand tracking: \(error)")
        }
    }
    
    private func publishHandTrackingUpdates() async {
        for await update in handTracking.anchorUpdates {
            guard update.anchor.isTracked else { continue }
            
            if update.anchor.chirality == .left {
                processLeftHandUpdate(anchor: update.anchor)
            } else if update.anchor.chirality == .right {
                processRightHandUpdate(anchor: update.anchor)
            }
        }
    }
    
    private func processLeftHandUpdate(anchor: HandAnchor) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.latestHandTracking.left = anchor
            self.updateLeftFingertipVisualizerEntities(anchor)
            
            let newTransform = Transform(matrix: anchor.originFromAnchorTransform)
            leftHandEntity.transform = newTransform
        }
    }
    
    private func processRightHandUpdate(anchor: HandAnchor) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.latestHandTracking.right = anchor
            self.updateRightFingertipVisualizerEntities(anchor)
            
            let newTransform = Transform(matrix: anchor.originFromAnchorTransform)
            rightHandEntity.transform = newTransform
        }
    }
    
    private func initializeVisualizationFingerTips() {
        for fingerTip in handJoints {
            let entity = createVisualizerFingertipEntity(for: fingerTip)
            leftFingerVisualizationEntities[fingerTip] = entity
            controlRootEntity.addChild(entity)
        }
        for fingerTip in handJoints {
            let entity = createVisualizerFingertipEntity(for: fingerTip)
            rightFingerVisualizationEntities[fingerTip] = entity
            controlRootEntity.addChild(entity)
        }
    }
    
    private func createVisualizerFingertipEntity(for jointName: HandSkeleton.JointName) -> FingerVisualizationEntity {
        var mode: HandVisualMode = .fingertip
        if jointName == .wrist {
            mode = .wrist
        }
        return FingerVisualizationEntity(mode: mode)
    }
    
    private func updateLeftFingertipVisualizerEntities(_ anchor: HandAnchor) {
        guard let handSkeleton = anchor.handSkeleton else { return }
        
        for (jointName, entity) in leftFingerVisualizationEntities {
            let joint = handSkeleton.joint(jointName)
            let worldTransform = matrix_multiply(anchor.originFromAnchorTransform, joint.anchorFromJointTransform)
            entity.setTransformMatrix(worldTransform, relativeTo: nil)
        }
    }
    
    private func updateRightFingertipVisualizerEntities(_ anchor: HandAnchor) {
        guard let handSkeleton = anchor.handSkeleton else { return }
        
        for (jointName, entity) in rightFingerVisualizationEntities {
            let joint = handSkeleton.joint(jointName)
            let worldTransform = matrix_multiply(anchor.originFromAnchorTransform, joint.anchorFromJointTransform)
            entity.setTransformMatrix(worldTransform, relativeTo: nil)
        }
    }
    
    private func removeAllHandEntities() {
        for entity in leftFingerVisualizationEntities.values {
            entity.removeFromParent()
        }
        for entity in rightFingerVisualizationEntities.values {
            entity.removeFromParent()
        }
        leftFingerVisualizationEntities.removeAll()
        rightFingerVisualizationEntities.removeAll()
    }
    
    /// Configures a trigger entity with the specified properties
    /// - Parameters:
    ///   - position: The position of the entity in 3D space
    ///   - stage: The interaction stage this trigger belongs to (default: 0)
    ///   - interactionData: Additional data for the interaction (default: nil)
    ///   - onInteraction: Closure called when the entity is interacted with
    /// - Returns: The configured ModelEntity
    public static func configureTriggerEntity(
        at position: SIMD3<Float>,
        stage: Int = 0,
        interactionData: [String: Any]? = nil,
        onInteraction: (() -> Void)? = nil
    ) -> ModelEntity {
        // Create the entity with a proper 3D model
        let entity = ModelEntity(mesh: .generateSphere(radius: 0.05))
        entity.position = position
        
        // Setup interaction target
        entity.setupToolInteractionTarget(
            stage: stage,
            interactionData: interactionData,
            collisionGroup: .interactionTarget,
            collisionMask: .tool,
            onInteraction: onInteraction
        )
        
        // Add to root entity
        rootEntity.addChild(entity)
        
        return entity
    }
}

/// Represents the type of hand being tracked
public enum HandType {
    case leftHand
    case rightHand
}

/// Represents the visual mode for hand tracking entities
public enum HandVisualMode {
    case wrist
    case fingertip
}

/// Represents the current state of hand tracking
public struct HandAnchorUpdate {
    public var left: HandAnchor?
    public var right: HandAnchor?
    
    public init(left: HandAnchor? = nil, right: HandAnchor? = nil) {
        self.left = left
        self.right = right
    }
}

/// Extension to provide additional functionality for HandSkeleton.JointName
public extension HandSkeleton.JointName {
    /// Returns true if this joint is a fingertip
    var isFingertip: Bool {
        switch self {
        case .indexFingerTip, .middleFingerTip, .ringFingerTip, .littleFingerTip, .thumbTip:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if this joint is a knuckle
    var isKnuckle: Bool {
        switch self {
        case .indexFingerKnuckle, .middleFingerKnuckle, .ringFingerKnuckle, .littleFingerKnuckle, .thumbKnuckle:
            return true
        default:
            return false
        }
    }
} 