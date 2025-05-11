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
    }
    
    private func addExampleEntities(to content: RealityViewContent) {
        // Create a few example entities with different positions
        let positions: [SIMD3<Float>] = [
            SIMD3<Float>(0.3, 0, 0),    // Right
            SIMD3<Float>(-0.3, 0, 0),   // Left
            SIMD3<Float>(0, 0.3, 0),    // Up
            SIMD3<Float>(0, -0.3, 0),   // Down
            SIMD3<Float>(0, 0, 0.3)     // Forward
        ]
        
        // Create entities at each position
        for (index, position) in positions.enumerated() {
            let entity = ModelEntity(mesh: .generateBox(size: 0.1))
            entity.position = position
            
            // Add collision component
            entity.components.set(CollisionComponent(
                shapes: [.generateBox(size: 0.1)],
                mode: .trigger,
                filter: CollisionFilter(group: .interactionTarget, mask: .tool)
            ))
            
            // Add physics body
            entity.components.set(PhysicsBodyComponent(
                shapes: [.generateBox(size: 0.1)],
                mass: 0,
                mode: .static
            ))
            
            // Add tool interaction target component
            let targetComponent = ToolInteractionTargetComponent(
                targetStage: 0,
                interactionData: ["index": index],
                collisionGroup: .interactionTarget,
                collisionMask: .tool
            )
            entity.toolInteractionTarget = targetComponent
            
            // Add to scene
            content.add(entity)
        }
    }
}

#Preview {
    HandTrackingView()
} 