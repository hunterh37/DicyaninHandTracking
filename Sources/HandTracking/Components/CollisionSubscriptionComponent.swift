//
//  CollisionSubscriptionComponent.swift
//  HandTracking
//
//  Created by Hunter Harris on 5/12/25.
//

import Foundation
import RealityKit
import Combine

/// A component that stores the collision subscription
public struct CollisionSubscriptionComponent: Component {
    var subscription: Cancellable?
    var sceneSubscription: Cancellable?
}
