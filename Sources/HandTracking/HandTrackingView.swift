import SwiftUI
import RealityKit
import HandTracking

/// A SwiftUI view that implements hand tracking functionality
public struct HandTrackingView: View {
    @StateObject private var handTracking = HandTracking()
    private let showHandVisualizations: Bool
    
    /// Creates a new HandTrackingView
    /// - Parameter showHandVisualizations: Whether to show hand visualization entities (default: true)
    public init(showHandVisualizations: Bool = true) {
        self.showHandVisualizations = showHandVisualizations
    }
    
    public var body: some View {
        RealityView { content in
            // Register required components
            HandTracking.registerComponents()
            
            // Add hand tracking entities to the scene
            content.add(handTracking.controlRootEntity)
            
            // Load camera model for right hand
            handTracking.loadModelForRightHand(modelName: "Camera") { entity in
                if let entity = entity {
                    print("📸 Camera model loaded successfully")
                }
            }
            // Add example interactive entities
            addExampleEntities(to: content)
            
            // Start hand tracking
            Task {
                await handTracking.start(showHandVisualizations: showHandVisualizations)
            }
        }
#if targetEnvironment(simulator)
        .gesture(dragGesture)
#endif
        .onDisappear {
            // Clean up hand tracking when view disappears
            handTracking.stop()
        }
    }
    
    // Allow drag gesture in simulator on tool objects for ease of debugging
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
