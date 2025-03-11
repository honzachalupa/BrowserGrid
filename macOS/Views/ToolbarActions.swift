import SwiftUI

struct ToolbarAction_openNewWindow: ToolbarContent {
    var onClick: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button {
                onClick()
            } label: {
                Label("New window", systemImage: "plus")
                    .labelStyle(.titleAndIcon)
            }
        }
    }
}

struct ToolbarAction_columnsCount: ToolbarContent {
    @Binding var columnsCount: Double
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .status) {
            HStack {
                Group {
                    Text("Columns:")
                    Text(String(format: "%.0f", columnsCount))
                }
                .opacity(0.6)
                
                Stepper("Columns", value: $columnsCount, step: 1)
            }
        }
    }
}

struct ToolbarAction_rowsCount: ToolbarContent {
    @Binding var rowsCount: Double
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .status) {
            HStack {
                Group {
                    Text("Rows:")
                    Text(String(format: "%.0f", rowsCount))
                }
                .opacity(0.6)
                
                Stepper("Rows", value: $rowsCount, step: 1)
            }
        }
    }
}

struct ToolbarAction_zoom: ToolbarContent {
    @Binding var zoom: Double
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .status) {
            HStack {
                Text("Zoom:")
                    .opacity(0.6)
                
                Slider(value: $zoom, in: 50.0...100.0, step: 5)
                    .frame(width: 150)
                
                Text("\(String(format: "%.0f", zoom)) %")
                    .opacity(0.6)
            }
            .padding(.leading, 20)
        }
    }
}

struct ToolbarAction_closeAllWindows: ToolbarContent {
    var onClick: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem {
            Button {
                onClick()
            } label: {
                Label("Close all windows", systemImage: "trash")
                    .labelStyle(.titleAndIcon)
            }
        }
    }
}

#Preview {
    @Previewable
    @State var columnsCount: Double = 3
    
    @Previewable
    @State var rowsCount: Double = 3
    
    @Previewable
    @State var zoom: Double = 70
    
    Color.clear
        .frame(width: 1200, height: 200)
        .toolbar {
            ToolbarAction_openNewWindow(onClick: {})
            ToolbarAction_columnsCount(columnsCount: $columnsCount)
            ToolbarAction_rowsCount(rowsCount: $rowsCount)
            ToolbarAction_zoom(zoom: $zoom)
            ToolbarAction_closeAllWindows(onClick: {})
        }
}
