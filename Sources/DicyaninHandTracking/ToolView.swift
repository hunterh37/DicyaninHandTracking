import SwiftUI
import RealityKit

/// A view that displays available tools and allows switching between them
public struct ToolView: View {
    @StateObject private var toolManager = ToolManager.shared
    @Environment(\.dismissWindow) private var dismissWindow
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List(toolManager.availableTools) { tool in
                Button {
                    toolManager.setActiveTool(tool)
                    dismissWindow()
                } label: {
                    HStack {
                        Text(tool.name)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if tool.id == toolManager.activeTool?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Tool")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismissWindow()
                    }
                }
            }
        }
    }
}

#Preview {
    ToolView()
} 