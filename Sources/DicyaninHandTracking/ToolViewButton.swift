import SwiftUI

/// A button that opens the tool selection view in a window
public struct ToolViewButton: View {
    @Environment(\.openWindow) private var openWindow
    
    public init() {}
    
    public var body: some View {
        Button {
            openWindow(id: "tool-view")
        } label: {
            Label("Change Tool", systemImage: "wrench.and.screwdriver")
        }
        .fontWeight(.semibold)
    }
}

#Preview {
    ToolViewButton()
} 
