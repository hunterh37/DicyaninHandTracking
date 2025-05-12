//
//  File.swift
//  HandTracking
//
//  Created by Hunter Harris on 5/12/25.
//

import Foundation
import RealityKit

/// A component that defines an object that can trigger interactions with hand-held tools
public struct ToolInteractionTargetComponent: Component {
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
