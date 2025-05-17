//
//  FingerVisualizationEntity.swift
//  HandTracking
//
//  Created by Hunter Harris on 5/11/25.
//

import Foundation
import RealityKit
import Combine
import UIKit
import SwiftUI

/// Entity used for visualizing finger positions and interactions
public class FingerVisualizationEntity: Entity, HasModel, HasCollision {
    public var mode: HandVisualMode = .fingertip
    public var isActiveVisual: Bool = false {
        didSet {
            updateMaterial()
        }
    }
    
    public required init(mode: HandVisualMode) {
        super.init()
        self.mode = mode
        self.components.set(dynamicModelComponent)
        self.generateCollisionShapes(recursive: true)
    }
    
    public init(mesh: MeshResource, materials: [SimpleMaterial], isActiveVisual: Bool = false) {
        super.init()
        self.components.set(ModelComponent(mesh: mesh, materials: materials))
        self.isActiveVisual = isActiveVisual
        self.generateCollisionShapes(recursive: true)
        updateMaterial()
    }
    
    @MainActor @preconcurrency required public init() {
        super.init()
        self.components.set(dynamicModelComponent)
        self.generateCollisionShapes(recursive: true)
    }
    
    private func simpleMaterial(isActive: Bool) -> SimpleMaterial {
        let color: SimpleMaterial.Color = isActive ? .init(.init(hex: "C0C0C0").opacity(0.8)) : .init(.clear)
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    private func updateMaterial() {
        self.components.set(dynamicModelComponent)
        if isActiveVisual {
            self.setOpacity(0, animated: true, duration: 0.5)
        } else {
            self.setOpacity(0, animated: true, duration: 0.5)
        }
    }
    
    private var dynamicModelComponent: ModelComponent {
        switch mode {
        case .wrist:
            return ModelComponent(mesh: .generateBox(width: 0.12, height: 0.01, depth: 0.06), materials: [simpleMaterial(isActive: isActiveVisual)])
        case .fingertip:
            return ModelComponent(mesh: .generateSphere(radius: 0.01), materials: [simpleMaterial(isActive: isActiveVisual)])
        }
    }
    
    public func setIsActiveVisual(_ isActive: Bool, removeAfter seconds: TimeInterval? = nil, addCollision: Bool = false) {
        self.isActiveVisual = isActive
        self.components.set(dynamicModelComponent)
        
        if addCollision {
            let shape: ShapeResource = (mode == .wrist) ? .generateBox(size: [0.12, 0.01, 0.06]) : .generateSphere(radius: 0.01)
            self.components.set(CollisionComponent(
                shapes: [shape],
                mode: .default))
            self.components.set(PhysicsBodyComponent(shapes: [.generateSphere(radius: 0.01)], mass: 1, mode: .kinematic))
        } else {
            self.components.remove(CollisionComponent.self)
            self.components.remove(PhysicsBodyComponent.self)
        }
        
        if let delay = seconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.isActiveVisual = false
                self?.setOpacity(0, animated: true, duration: 0.5)
                self?.components.set(self?.dynamicModelComponent ?? ModelComponent(mesh: .generateBox(size: 0.1), materials: []))
            }
        }
    }
}

private var playbackCompletedSubscriptions: Set<AnyCancellable> = .init()

extension Entity {
    
    /// The opacity value applied to the entity and its descendants.
    ///
    /// `OpacityComponent` is assigned to the entity if it doesn't already exist.
    var opacity: Float {
        get {
            return components[OpacityComponent.self]?.opacity ?? 1
        }
        set {
            if !components.has(OpacityComponent.self) {
                components[OpacityComponent.self] = OpacityComponent(opacity: newValue)
            } else {
                components[OpacityComponent.self]?.opacity = newValue
            }
        }
    }
    
    /// Sets the opacity value applied to the entity and its descendants with optional animation.
    ///
    /// `OpacityComponent` is assigned to the entity if it doesn't already exist.
    func setOpacity(_ opacity: Float, animated: Bool, duration: TimeInterval = 0.01, delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        guard animated else {
            self.opacity = opacity
            return
        }
        
        if !components.has(OpacityComponent.self) {
            components[OpacityComponent.self] = OpacityComponent(opacity: 1)
        }

        let animation = FromToByAnimation(name: "Entity/setOpacity", to: opacity, duration: duration, timing: .linear, isAdditive: false, bindTarget: .opacity, delay: delay)
        
        do {
            let animationResource: AnimationResource = try .generate(with: animation)
            let animationPlaybackController = playAnimation(animationResource)
            
            if completion != nil {
                scene?.publisher(for: AnimationEvents.PlaybackCompleted.self)
                    .filter { $0.playbackController == animationPlaybackController }
                    .sink(receiveValue: { event in
                        completion?()
                    }).store(in: &playbackCompletedSubscriptions)
            }
        } catch {
            assertionFailure("Could not generate animation: \(error.localizedDescription)")
        }
    }
}

// Utility extension to create a UIColor from a hex string
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized
        let length = hexSanitized.count

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        if length == 6 {
            let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: 1.0)
        } else {
            return nil
        }
    }
    
    // Convert UIColor to a hex string
    func toHex() -> String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let r = Int(red * 255.0)
        let g = Int(green * 255.0)
        let b = Int(blue * 255.0)

        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension Color {
    init(hex: String) {
        if let uiColor = UIColor(hex: hex) {
            self.init(uiColor)
        } else {
            self.init(.red)
        }
    }

    // Add a method to retrieve the hex value from a Color object
    func toHex() -> String? {
        return UIColor(self).toHex()
    }
} 
