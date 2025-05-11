# HandTracking

A Swift package for hand tracking and visualization in visionOS and iOS applications.

## Features

- Real-time hand tracking using ARKit
- Support for both left and right hands
- Visual representation of hand joints and fingers
- Customizable finger visualization
- Collision detection support
- Animation support for visual feedback

## Requirements

- iOS 17.0+ / visionOS 1.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/HandTracking.git", from: "1.0.0")
]
```

## Usage

```swift
import HandTracking
import RealityKit
import SwiftUI

struct ImmersiveView: View {
    @StateObject private var handTracking = HandTracking()
    
    var body: some View {
        RealityView { content in
            // Register required components
            HandTracking.registerComponents()
            
            // Add hand tracking entities to the scene
            content.add(handTracking.controlRootEntity)
            
            // Start hand tracking
            Task {
                await handTracking.start()
            }
        }
        .onDisappear {
            // Clean up hand tracking when view disappears
            handTracking.stop()
        }
    }
}

// Example of loading a 3D model for the right hand
struct ModelLoadingExample: View {
    @StateObject private var handTracking = HandTracking()
    
    var body: some View {
        RealityView { content in
            // Register and setup hand tracking
            HandTracking.registerComponents()
            content.add(handTracking.controlRootEntity)
            
            Task {
                await handTracking.start()
                
                // Load a model for the right hand
                handTracking.loadModelForRightHand(modelName: "sword") { entity in
                    if let entity = entity {
                        print("Model loaded successfully")
                    }
                }
            }
        }
        .onDisappear {
            handTracking.stop()
        }
    }
}

### Required Setup

1. Add the following key to your Info.plist file to request hand tracking permissions:
```xml
<key>NSHandsTrackingUsageDescription</key>
<string>This app needs access to hand tracking to enable hand interaction features.</string>
```

## API Reference

### HandTracking

The main class for hand tracking functionality.

#### Properties

- `latestHandTracking`: Current state of hand tracking
- `isRightHanded`: Whether the user is right-handed
- `controlRootEntity`: Root entity for hand visualization

#### Methods

- `start(showHandVisualizations:)`: Start hand tracking with optional hand visualization
- `stop()`: Stop hand tracking
- `highlightFinger(_:hand:duration:isActive:)`: Highlight a specific finger
- `setFingerActive(_:onHand:isActive:)`: Set a finger's active state
- `setAllFingersActive(_:duration:addCollision:)`: Set all fingers' active state

Example usage:
```swift
// Start with hand visualizations (default)
await handTracking.start()

// Start without hand visualizations
await handTracking.start(showHandVisualizations: false)
```

#### Model Loading Methods

- `loadModelForRightHand(modelName:completion:)`: Load a 3D model by name and attach it to the right hand
- `loadModelForRightHand(from:completion:)`: Load a 3D model from a URL and attach it to the right hand
- `removeModelFromRightHand()`: Remove any currently attached model from the right hand

### Interaction System

The package includes a built-in interaction system for hand-held tools:

#### Tool Interaction Components

- `ToolInteractionTargetComponent`: Defines objects that can be interacted with using hand-held tools
- `ToolCollisionTriggerComponent`: Defines the interaction stages and progression for hand-held tools
- `CollisionSubscriptionComponent`: Manages collision event subscriptions

Example usage:
```swift
// Create an interaction target
let targetEntity = ModelEntity(mesh: .generateBox(size: 0.1))
targetEntity.setupToolInteractionTarget(
    stage: 0,
    interactionData: ["action": "activate"],
    collisionGroup: .interactionTarget,
    collisionMask: .tool
)

// Load a tool model that will interact with targets
handTracking.loadModelForRightHand(modelName: "tool") { entity in
    if let entity = entity {
        // The tool is automatically set up with collision detection
        // and will trigger interactions when colliding with targets
    }
}
```

### FingerVisualizationEntity

Entity used for visualizing finger positions and interactions.

#### Properties

- `mode`: Visual mode (wrist or fingertip)
- `isActiveVisual`: Whether the entity is visually active

#### Methods

- `setIsActiveVisual(_:removeAfter:addCollision:)`: Set the entity's active state

## License

This project is licensed under the MIT License - see the LICENSE file for details. 