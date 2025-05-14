//
//  HandTracking.swift
//  HandTracking
//
//  Created by Hunter Harris on 5/11/25.
//

import RealityKit
import ARKit
import SwiftUI
import Combine
import DicyaninARKitSession

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

/// A class that manages hand tracking and gesture recognition
public class HandTracking: HandTrackingProtocol {
    /// Shared instance of the hand tracking manager
    public static let shared = HandTracking()
    
    private var cancellables = Set<AnyCancellable>()
    private var handTrackingCancellable: AnyCancellable?
    
    public init() {
        setupHandTrackingSubscription()
    }
    
    // MARK: - Properties
    var currentToolEntity: Entity?
    
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
    
    // MARK: - Public Methods
    /// Starts hand tracking
    /// - Parameter showHandVisualizations: Whether to show hand visualization entities
    public func start(showHandVisualizations: Bool = true) async {
        Task { @MainActor in
            rightHandEntity.removeFromParent()
            leftHandEntity.removeFromParent()
            rightHandEntity.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.2)], mode: .trigger))
            rightHandEntity.components.set(PhysicsBodyComponent(shapes: [.generateSphere(radius: 0.2)], mass: 10, mode: .kinematic))
            
            controlRootEntity.addChild(rightHandEntity)
            controlRootEntity.addChild(leftHandEntity)
            
            if showHandVisualizations {
                initializeVisualizationFingerTips()
            }
            
            do {
                try await ARKitSessionManager.shared.start()
            } catch {
                print("Failed to start hand tracking: \(error)")
            }
        }
    }
    
    /// Stops hand tracking
    public func stop() {
        ARKitSessionManager.shared.stop()
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
    
    /// Removes any currently attached model from the right hand
    func removeModelFromRightHand() {
        Task { @MainActor in
            // Remove the current tool entity if it exists
            if let currentTool = currentToolEntity {
                currentTool.removeFromParent()
                currentToolEntity = nil
            }
        }
    }
    
    // MARK: - Private Methods
    private func setupHandTrackingSubscription() {
        handTrackingCancellable = ARKitSessionManager.shared.handTrackingUpdates
            .sink { [weak self] update in
                // Convert DicyaninARKitSession.HandAnchorUpdate to HandTracking.HandAnchorUpdate
                let convertedUpdate = HandAnchorUpdate(
                    left: update.left,
                    right: update.right
                )
                self?.handleHandUpdate(convertedUpdate)
            }
    }
    
    private func handleHandUpdate(_ update: HandAnchorUpdate) {
        // Process hand updates as before
        if let leftHand = update.left {
            processHandAnchor(leftHand)
        }
        if let rightHand = update.right {
            processHandAnchor(rightHand)
        }
    }
    
    private func processHandAnchor(_ anchor: HandAnchor) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.latestHandTracking = HandAnchorUpdate(left: anchor, right: nil)
            self.updateFingertipVisualizerEntities(anchor)
            
            let newTransform = Transform(matrix: anchor.originFromAnchorTransform)
            if anchor.chirality == .left {
                leftHandEntity.transform = newTransform
            } else if anchor.chirality == .right {
                rightHandEntity.transform = newTransform
            }
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
    
    private func updateFingertipVisualizerEntities(_ anchor: HandAnchor) {
        guard let handSkeleton = anchor.handSkeleton else { return }
        
        for (jointName, entity) in leftFingerVisualizationEntities {
            let joint = handSkeleton.joint(jointName)
            let worldTransform = matrix_multiply(anchor.originFromAnchorTransform, joint.anchorFromJointTransform)
            entity.setTransformMatrix(worldTransform, relativeTo: nil)
        }
        
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
    public func configureTriggerEntity(
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
        
        // Add to controlRootEntity
        controlRootEntity.addChild(entity)
        
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
