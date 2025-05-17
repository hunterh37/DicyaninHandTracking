import SwiftUI
import RealityKit
import DicyaninHandTracking
import DicyaninARKitSession

/// A SwiftUI view that implements hand tracking functionality
public struct HandTrackingView: View {
    @StateObject private var handTracking = DicyaninHandTracking.shared
    @StateObject private var toolManager = ToolManager.shared
    private let showHandVisualizations: Bool
    private let tools: [Tool]
    
    /// Creates a new HandTrackingView with default tools
    /// - Parameter showHandVisualizations: Whether to show hand visualization entities (default: true)
    public init(showHandVisualizations: Bool = true) {
        self.showHandVisualizations = showHandVisualizations
        
        self.tools = [
            Tool(id: "camera", name: "Camera", modelName: "Camera"),
            Tool(id: "flower", name: "Flower", modelName: "Flower")
        ]
    }
    
    /// Creates a new HandTrackingView with custom tools
    /// - Parameters:
    ///   - tools: Array of tools to use
    ///   - showHandVisualizations: Whether to show hand visualization entities (default: true)
    public init(tools: [Tool], showHandVisualizations: Bool = true) {
        self.showHandVisualizations = showHandVisualizations
        self.tools = tools
    }
    
    public var body: some View {
        RealityView { content in
            // Register required components
            DicyaninHandTracking.registerComponents()
            
            // Configure tools
            toolManager.configureTools(tools)
            
            // Add hand tracking entities to the scene
            content.add(handTracking.controlRootEntity)
            
            // Set up tool change handler
            toolManager.onToolChanged = { tool in
                // Remove any existing model
                handTracking.removeModelFromRightHand()
                
                // Load the new tool model
                handTracking.loadModelForRightHand(modelName: tool.modelName) { entity in
                    if let entity = entity {
                        print("📸 \(tool.name) model loaded successfully")
                    }
                }
            }
            
            // Load initial tool model
            if let activeTool = toolManager.activeTool {
                handTracking.loadModelForRightHand(modelName: activeTool.modelName) { entity in
                    if let entity = entity {
                        print("📸 \(activeTool.name) model loaded successfully")
                    }
                }
            }
            
            // Add example interactive entities
            addExampleEntities(to: content)
            
            // Start hand tracking
            Task {
                await handTracking.start(showHandVisualizations: showHandVisualizations)
            }
        }
        .onDisappear {
            // Clean up hand tracking when view disappears
            handTracking.stop()
        }
#if targetEnvironment(simulator)
        // Allow drag gesture in simulator on tool objects for ease of debugging
        .gesture(dragGesture)
#endif
    }
    var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in // When drag begins/changes, set Rigidbody to kinematic
                guard let parent = value.entity.parent else { return }
                value.entity.position = value.convert(value.location3D, from: .local, to: parent)
                value.entity.components[PhysicsBodyComponent.self]?.mode = .kinematic
            }
            .onEnded({ value in // When drag ends, set Rigidbody back to dynamic
                value.entity.components[PhysicsBodyComponent.self]?.mode = .dynamic
                
            })
    }
    
    private func addExampleEntities(to content: RealityViewContent) {
        // Create a few example entities with different positions
        let positions: [SIMD3<Float>] = [
            SIMD3<Float>(0.5, 0.5, 0.5),    // Right, Up, Forward
            SIMD3<Float>(-0.5, 0.5, 0.5),   // Left, Up, Forward
            SIMD3<Float>(0, 0.7, 0.5),      // Center, Higher Up, Forward
            SIMD3<Float>(0.5, 0.5, -0.5),   // Right, Up, Back
            SIMD3<Float>(-0.5, 0.5, -0.5)   // Left, Up, Back
        ]
        
        let boxSize = SIMD3<Float>(0.1, 0.1, 0.1)
        
        // Create entities at each position
        for (index, position) in positions.enumerated() {
            let entity = ModelEntity(mesh: .generateBox(size: boxSize))
            entity.position = position
            
            // Add to scene first
            content.add(entity)
            
            // Now set up collision and interaction after entity is in scene
            entity.components.set(CollisionComponent(
                shapes: [.generateBox(size: boxSize)],
                mode: .trigger,
                filter: CollisionFilter(group: .interactionTarget, mask: .tool)
            ))
            
            entity.components.set(PhysicsBodyComponent(
                shapes: [.generateBox(size: boxSize)],
                mass: 0,
                mode: .static
            ))
            
            Task {
                await try? Task.sleep(for: .seconds(1))
                // Setup interaction target with completion handler
                entity.setupToolInteractionTarget(
                    stage: 0,
                    interactionData: ["index": index],
                    collisionGroup: .interactionTarget,
                    collisionMask: .tool
                ) {
                    print("🎯 Interacted with entity at position: \(position)")
                    
                    // Example: Change the entity's color when interacted with
                    if var modelComponent = entity.components[ModelComponent.self] {
                        modelComponent.materials = [SimpleMaterial(color: .green, isMetallic: false)]
                        entity.components[ModelComponent.self] = modelComponent
                    }
                }
            }
            
            print("📦 Added entity at position: \(position)")
        }
    }
}

#Preview {
    HandTrackingView()
} 
