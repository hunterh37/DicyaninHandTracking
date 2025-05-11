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
        } update: { content in
            // Update hand tracking visualization
            if handTracking.latestHandTracking.right != nil {
                handTracking.setAllFingersActive(true, duration: nil, addCollision: true)
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

- `start()`: Start hand tracking
- `stop()`: Stop hand tracking
- `highlightFinger(_:hand:duration:isActive:)`: Highlight a specific finger
- `setFingerActive(_:onHand:isActive:)`: Set a finger's active state
- `setAllFingersActive(_:duration:addCollision:)`: Set all fingers' active state

#### Model Loading Methods

- `loadModelForRightHand(modelName:completion:)`: Load a 3D model by name and attach it to the right hand
- `loadModelForRightHand(from:completion:)`: Load a 3D model from a URL and attach it to the right hand
- `removeModelFromRightHand()`: Remove any currently attached model from the right hand

Example usage:
```swift
// Load a model by name
handTracking.loadModelForRightHand(modelName: "sword") { entity in
    if let entity = entity {
        print("Model loaded successfully")
    }
}

// Load a model from URL
if let url = URL(string: "https://example.com/models/sword.usdz") {
    handTracking.loadModelForRightHand(from: url) { entity in
        if let entity = entity {
            print("Model loaded successfully")
        }
    }
}

// Remove the current model
handTracking.removeModelFromRightHand()
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