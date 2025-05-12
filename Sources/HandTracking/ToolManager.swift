import RealityKit
import SwiftUI
import Combine

/// Represents a tool that can be used in the hand tracking system
public struct Tool: Identifiable {
    public let id: String
    public let name: String
    public let modelName: String
    public let stages: Int
    public let stageDescriptions: [String]
    
    public init(id: String, name: String, modelName: String, stages: Int = 1, stageDescriptions: [String] = ["Ready"]) {
        self.id = id
        self.name = name
        self.modelName = modelName
        self.stages = stages
        self.stageDescriptions = stageDescriptions
    }
}

/// Manages the available tools and the currently active tool
public class ToolManager: ObservableObject {
    public static let shared = ToolManager()
    
    @Published public private(set) var availableTools: [Tool] = []
    @Published public private(set) var activeTool: Tool?
    
    // Callback for when tool changes
    public var onToolChanged: ((Tool) -> Void)?
    
    private init() {
        // Initialize with default tools
        setupDefaultTools()
    }
    
    /// Sets up the default set of tools
    private func setupDefaultTools() {
        availableTools = [
            Tool(id: "camera", name: "Camera", modelName: "Camera"),
            Tool(id: "flower", name: "Flower", modelName: "Flower")
        ]
        
        // Set the first tool as active by default
        if let firstTool = availableTools.first {
            setActiveTool(firstTool)
        }
    }
    
    /// Sets the active tool
    /// - Parameter tool: The tool to set as active
    public func setActiveTool(_ tool: Tool) {
        // Only update if the tool is different
        guard activeTool?.id != tool.id else { return }
        
        activeTool = tool
        
        // Notify listeners of the tool change
        onToolChanged?(tool)
    }
    
    /// Sets the active tool by ID
    /// - Parameter toolId: The ID of the tool to set as active
    public func setActiveTool(id toolId: String) {
        if let tool = availableTools.first(where: { $0.id == toolId }) {
            setActiveTool(tool)
        }
    }
    
    /// Adds a new tool to the available tools
    /// - Parameter tool: The tool to add
    public func addTool(_ tool: Tool) {
        availableTools.append(tool)
    }
    
    /// Removes a tool from the available tools
    /// - Parameter toolId: The ID of the tool to remove
    public func removeTool(id toolId: String) {
        availableTools.removeAll { $0.id == toolId }
        
        // If we removed the active tool, set a new active tool
        if activeTool?.id == toolId {
            activeTool = availableTools.first
            if let newTool = activeTool {
                onToolChanged?(newTool)
            }
        }
    }
} 