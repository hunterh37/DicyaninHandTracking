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

class YourViewController: UIViewController {
    private var handTracking: HandTracking!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize hand tracking
        handTracking = HandTracking()
        
        // Start tracking
        Task {
            await handTracking.start()
        }
    }
    
    // Example of highlighting a finger
    func highlightIndexFinger() {
        handTracking.highlightFinger(.indexFingerTip, hand: .rightHand, duration: 1.0, isActive: true)
    }
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

- `start()`: Start hand tracking
- `stop()`: Stop hand tracking
- `highlightFinger(_:hand:duration:isActive:)`: Highlight a specific finger
- `setFingerActive(_:onHand:isActive:)`: Set a finger's active state
- `setAllFingersActive(_:duration:addCollision:)`: Set all fingers' active state

### FingerVisualizationEntity

Entity used for visualizing finger positions and interactions.

#### Properties

- `mode`: Visual mode (wrist or fingertip)
- `isActiveVisual`: Whether the entity is visually active

#### Methods

- `setIsActiveVisual(_:removeAfter:addCollision:)`: Set the entity's active state

## License

This project is licensed under the MIT License - see the LICENSE file for details. 