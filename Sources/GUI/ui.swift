import SwiftUI
import AppKit

// MARK: - Application Delegate & Window Initialization
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 750),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )

        window.center()
        window.setFrameAutosaveName("MemoryVisualizer")
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.contentView = NSHostingView(rootView: ContentView())
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

struct AppWindow {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

// MARK: - Root View
struct ContentView: View {
    @State private var inputText = ""
    @State private var selectedDataType: DataType = .string
    @State private var errorMessage = ""
    @StateObject private var memoryManager = MemoryManager.shared

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text("Memory Visualizer")
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .foregroundColor(.black)
                        
                        Text("Educational Tool for Computer Architecture")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .padding(.top, 40)

                    MemoryStatisticsView(statistics: memoryManager.statistics)

                    VStack(spacing: 20) {
                        Text("Allocate Memory")
                            .font(.system(size: 20, weight: .semibold, design: .default))
                            .foregroundColor(.black)

                        VStack(spacing: 12) {
                            Text("Select Data Type:")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.black)
                            
                            HStack(spacing: 8) {
                                ForEach(DataType.allCases, id: \.self) { type in
                                    Button(type.rawValue) {
                                        selectedDataType = type
                                        errorMessage = ""
                                    }
                                    .buttonStyle(DataTypeButtonStyle(isSelected: selectedDataType == type))
                                }
                            }
                            .frame(maxWidth: 400)
                        }
                        
                        TextField("", text: $inputText)
                            .textFieldStyle(CustomTextFieldStyle())
                            .frame(maxWidth: 400)
                            .textSelection(.enabled)
                            .focusable(true)
                            .onChange(of: inputText) {
                                errorMessage = ""
                            }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .frame(maxWidth: 400)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                        }
                    }

                    HStack(spacing: 16) {
                        Button("Allocate Memory") {
                            if memoryManager.allocateMemory(inputText, dataType: selectedDataType) != nil {
                                errorMessage = ""
                                inputText = ""
                            } else {
                                switch selectedDataType {
                                case .string:
                                    errorMessage = "Invalid string input"
                                case .integer:
                                    errorMessage = "Please enter a valid integer"
                                case .float:
                                    errorMessage = "Please enter a valid decimal number"
                                case .array:
                                    errorMessage = "Please enter valid comma-separated values\n(e.g., 1,2,3 or apple,banana,cherry)"
                                }
                            }
                        }
                        .disabled(inputText.isEmpty)
                        .buttonStyle(PrimaryButtonStyle(isDisabled: inputText.isEmpty))
                        
                        Button("Deallocate All") {
                            memoryManager.deallocateAllMemory()
                        }
                        .disabled(memoryManager.activeBlocks.isEmpty)
                        .buttonStyle(SecondaryButtonStyle(isDisabled: memoryManager.activeBlocks.isEmpty))
                    }

                    ActiveMemoryBlocksView(blocks: memoryManager.activeBlocks) { blockId in
                        memoryManager.deallocateMemory(blockId)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 700)
    }
}

// MARK: - Memory Visualization View
struct MemoryView: View {
    var address: String
    var content: String
    var isAllocated: Bool

    var body: some View {
        VStack(spacing: 24) {
            if isAllocated {
                AllocatedMemoryView(address: address, content: content)
            } else {
                EmptyMemoryView()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Allocated Memory View
struct AllocatedMemoryView: View {
    let address: String
    let content: String
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
                
                Text("Memory Allocated")
                    .font(.system(size: 24, weight: .semibold, design: .default))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            MemoryInfoCard(address: address, content: content)
            
            if !content.isEmpty {
                ByteRepresentationView(content: content)
            }
        }
    }
}

// MARK: - Empty Memory View
struct EmptyMemoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "memorychip")
                .font(.system(size: 48))
                .foregroundColor(.black.opacity(0.3))
            
            Text("No Memory Allocated")
                .font(.system(size: 24, weight: .semibold, design: .default))
                .foregroundColor(.black)
            
            TutorialCard()
        }
    }
}

// MARK: - Supporting Views
struct MemoryInfoCard: View {
    let address: String
    let content: String
    
    var body: some View {
        VStack(spacing: 20) {
            MemoryInfoRow(title: "Memory Address", value: address, color: .blue)
            MemoryInfoRow(title: "Stored Content", value: "\"\(content)\"", color: .black)
            MemoryInfoRow(title: "Size in Memory", value: "\(content.utf8.count + 1) bytes", color: .orange)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ByteRepresentationView: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Byte Representation")
                .font(.system(size: 20, weight: .semibold, design: .default))
                .foregroundColor(.black)
            
            ByteGrid(content: content)
            
            Text("Red byte (00) represents null terminator")
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.black.opacity(0.6))
                .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ByteGrid: View {
    let content: String
    
    var body: some View {
        let bytes = Array(content.utf8) + [0]
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 12) {
            ForEach(0..<bytes.count, id: \.self) { index in
                ByteCell(byte: bytes[index], index: index)
            }
        }
    }
}

struct ByteCell: View {
    let byte: UInt8
    let index: Int
    
    var body: some View {
        VStack(spacing: 6) {
            Text(String(format: "%02X", byte))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(byte == 0 ? .red : .black)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(byte == 0 ? Color.red.opacity(0.1) : Color.black.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(byte == 0 ? Color.red.opacity(0.3) : Color.black.opacity(0.15), lineWidth: 1)
                        )
                )
            
            Text("[\(index)]")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.black.opacity(0.6))
        }
    }
}

struct TutorialCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Memory Allocation Tutorial")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 8) {
                TutorialStep(number: "1", text: "Enter text in the field above")
                TutorialStep(number: "2", text: "Click 'Allocate Memory' to reserve space")
                TutorialStep(number: "3", text: "Observe the memory address and content")
                TutorialStep(number: "4", text: "See byte representation in hexadecimal")
                TutorialStep(number: "5", text: "Use 'Deallocate' to free the memory")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Custom Components

struct MemoryInfoRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

struct TutorialStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold, design: .default))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.black))
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .default))
                .foregroundColor(.black.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .default))
            .foregroundColor(isDisabled ? .white.opacity(0.6) : .white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDisabled ? Color.black.opacity(0.3) : Color.black)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .default))
            .foregroundColor(isDisabled ? .black.opacity(0.3) : .black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDisabled ? Color.black.opacity(0.2) : Color.black, lineWidth: 1.5)
                    )
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DataTypeButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .default))
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.black : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                    )
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Memory Statistics View

struct MemoryStatisticsView: View {
    let statistics: MemoryStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Memory Statistics")
                .font(.system(size: 20, weight: .semibold, design: .default))
                .foregroundColor(.black)
            
            HStack(spacing: 20) {
                StatCard(title: "Active", value: "\(statistics.currentAllocations)", color: .green)
                StatCard(title: "Total", value: "\(statistics.totalAllocations)", color: .blue)
                StatCard(title: "Current Bytes", value: "\(statistics.currentBytesAllocated)", color: .orange)
                StatCard(title: "Peak Bytes", value: "\(statistics.peakBytesAllocated)", color: .red)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.black.opacity(0.7))
        }
        .frame(minWidth: 80)
    }
}

// MARK: - Active Memory Blocks View

struct ActiveMemoryBlocksView: View {
    let blocks: [MemoryBlock]
    let onDeallocate: (UUID) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if blocks.isEmpty {
                EmptyMemoryView()
            } else {
                VStack(spacing: 12) {
                    Text("Active Memory Allocations (\(blocks.count))")
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .foregroundColor(.black)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(blocks) { block in
                            MemoryBlockCard(block: block) {
                                onDeallocate(block.id)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MemoryBlockCard: View {
    let block: MemoryBlock
    let onDeallocate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(block.dataType.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .foregroundColor(.black)
                    
                    Text("Allocated: \(timeAgo(block.allocatedAt))")
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(.black.opacity(0.6))
                }
                
                Spacer()
                
                Button("Deallocate") {
                    onDeallocate()
                }
                .buttonStyle(DeallocateButtonStyle())
            }
            
            VStack(spacing: 12) {
                MemoryInfoRow(title: "Address", value: block.address, color: .blue)
                MemoryInfoRow(title: "Content", value: "\"\(block.content)\"", color: .black)
                MemoryInfoRow(title: "Size", value: "\(block.size) bytes", color: .orange)
            }
            
            if !block.content.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Byte Representation")
                        .font(.system(size: 14, weight: .semibold, design: .default))
                        .foregroundColor(.black)
                    
                    ByteGridCompact(bytes: block.bytesRepresentation)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 {
            return "\(seconds)s ago"
        } else {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        }
    }
}

struct ByteGridCompact: View {
    let bytes: [UInt8]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: min(bytes.count, 8)), spacing: 10) {
            ForEach(0..<min(bytes.count, 16), id: \.self) { index in
                Text(String(format: "%02X", bytes[index]))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(bytes[index] == 0 ? .red : .black)
                    .frame(width: 32, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(bytes[index] == 0 ? Color.red.opacity(0.1) : Color.black.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(bytes[index] == 0 ? Color.red.opacity(0.3) : Color.black.opacity(0.15), lineWidth: 1)
                            )
                    )
            }
            
            if bytes.count > 16 {
                Text("...")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black.opacity(0.5))
                    .frame(width: 32, height: 28)
            }
        }
    }
}

struct DeallocateButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .default))
            .foregroundColor(.red)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom TextField Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .medium, design: .default))
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
            .background(Color.clear)
    }
}