

# HandTracking

A Swift package for hand tracking and gesture recognition in visionOS applications.

## Overview

HandTracking provides a simple and efficient way to implement hand tracking and gesture recognition in your visionOS applications. It offers a high-level API for tracking hand movements, detecting gestures, and managing hand interactions with 3D objects.

## Features

- Hand tracking and gesture recognition
- Support for both visionOS 
- Easy integration with RealityKit
- Customizable hand visualization
- Tool interaction system
- Collision detection and handling

## Requirements

- visionOS 1.0+
- Xcode 15.0+
- Swift 5.9+

## Dependencies

### DicyaninARKitSession

HandTracking depends on [DicyaninHandSessionManager](https://github.com/hunterh37/DicyaninHandSessionManager),

a package that provides centralized ARKit session management. This dependency is necessary because:

- In visionOS, only one HandTrackingProvider can be active at a time
- Multiple packages or components might need hand tracking data
- DicyaninARKitSession manages a single ARKit session and distributes hand tracking updates to all subscribers
- It ensures efficient resource usage and prevents conflicts between different parts of your app

To add this dependency to your project, include it in your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/dicyanin/DicyaninARKitSession.git", from: "0.0.1")
]
```

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/hunterh37/HandTracking.git", from: "0.0.1")
]
```

## Usage

### Basic Setup

```swift
import HandTracking
import RealityKit

// Create a hand tracking view
let handTrackingView = HandTrackingView()

// Or create with custom tools
let tools = [
    Tool(id: "camera", name: "Camera", modelName: "Camera"),
    Tool(id: "flower", name: "Flower", modelName: "Flower")
]
let customHandTrackingView = HandTrackingView(tools: tools)
```

### Tool Interaction

```swift
// Configure a trigger entity
let trigger = handTracking.configureTriggerEntity(
    at: SIMD3<Float>(0, 0, 0),
    stage: 0,
    interactionData: ["key": "value"]
) { 
    print("Trigger activated!")
}
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

### HandTrackingView

A SwiftUI view that implements hand tracking functionality.

#### Initializers

- `init(showHandVisualizations:)`: Create a view with default tools
- `init(tools:showHandVisualizations:)`: Create a view with custom tools

### ToolManager

Manages available tools and the currently active tool.

#### Properties

- `availableTools`: Array of available tools
- `activeTool`: Currently active tool
- `onToolChanged`: Callback when the active tool changes

#### Methods

- `configureTools(_:)`: Configure the available tools
- `setActiveTool(_:)`: Set the active tool
- `setActiveTool(id:)`: Set the active tool by ID
- `addTool(_:)`: Add a new tool
- `removeTool(id:)`: Remove a tool

### Required Setup

1. Add the following key to your Info.plist file to request hand tracking permissions:
```xml
<key>NSHandsTrackingUsageDescription</key>
<string>This app needs access to hand tracking to enable hand interaction features.</string>
```


## Acknowledgments

- Apple's RealityKit and ARKit frameworks
- The visionOS development community
- All contributors to this project 
