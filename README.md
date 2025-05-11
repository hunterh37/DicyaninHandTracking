# HandTracking

A Swift package for hand tracking and visualization in visionOS applications. This package provides real-time hand tracking, visualization, and interaction capabilities for spatial computing applications.

## Quick Start

1. Add the package to your project
2. Add the required Info.plist key
3. Use the `HandTrackingView` or implement hand tracking manually
4. Create interactive entities that respond to hand-held tools

## Features

- Real-time hand tracking using ARKit
- Support for both left and right hands
- Visual representation of hand joints and fingers
- Customizable finger visualization
- Collision detection support
- Animation support for visual feedback
- Built-in interaction system for hand-held tools

## Requirements

- visionOS 1.0+
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

### Basic Usage

The package provides a ready-to-use SwiftUI view for hand tracking:

```swift
import SwiftUI
import RealityKit
import HandTracking

struct ContentView: View {
    var body: some View {
        HandTrackingView()
    }
}
```

### Creating Interactive Entities

To create an entity that can be interacted with using hand-held tools:

```swift
// Create a trigger entity at a specific position
let trigger = HandTracking.configureTriggerEntity(
    at: SIMD3<Float>(0.3, 0, 0),
    interactionData: ["type": "trigger"]
) {
    // This closure is called when the entity is interacted with
    print("Trigger activated!")
}

// You can also load a custom 3D model for the trigger
if let modelEntity = try? ModelEntity.load(named: "trigger_model") {
    modelEntity.position = SIMD3<Float>(0.3, 0, 0)
    modelEntity.setupToolInteractionTarget(
        stage: 0,
        interactionData: ["type": "custom_trigger"]
    ) {
        print("Custom trigger activated!")
    }
    rootEntity.addChild(modelEntity)
}
```

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
let targetEntity = ModelEntity(mesh: .generateSphere(radius: 0.05))
targetEntity.setupToolInteractionTarget(
    stage: 0,
    interactionData: ["action": "activate"]
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