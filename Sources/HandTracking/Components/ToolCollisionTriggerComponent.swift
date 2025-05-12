//
//  File.swift
//  HandTracking
//
//  Created by Hunter Harris on 5/12/25.
//

import Foundation
import RealityKit

/// A component that defines collision triggers for tool interactions
public struct ToolCollisionTriggerComponent: Component {
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
