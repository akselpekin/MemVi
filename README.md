# MemVi - Memory Visualizer

An educational GUI tool for computer architecture learning, focusing on memory allocation and visualization.

## Features

- **Interactive Memory Allocation**: Users can input text and see how it's stored in system memory
- **Real Memory Addresses**: Shows actual memory addresses where data is allocated
- **Byte-level Visualization**: Displays hexadecimal representation of stored data
- **Educational Interface**: Clear visual feedback and instructional text
- **Memory Management**: Allocate and deallocate memory to understand memory lifecycle

## Educational Value

This tool helps students understand:
- How data is stored in computer memory
- Memory addresses and their representation
- Byte-level data storage including null terminators
- Memory allocation and deallocation processes
- The relationship between text and its binary representation

## Building and Running

Requirements:
- macOS 15.0+
- Swift 6.1+
- Xcode (for development)

### Build the project:
```bash
cd /path/to/MemVi
swift build
```

### Launch the GUI application:

**Option 1 - Using open command (Recommended):**
```bash
swift build && open .build/debug/MemVi
```

**Option 2 - Using the provided launch script:**
```bash
./launch.sh
```

**Option 3 - Direct execution:**
```bash
.build/debug/MemVi &
```

**Note:** The `&` symbol runs the app in the background, allowing you to continue using the terminal while the GUI is open.

## Usage

1. **Enter Text**: Type any text in the input field
2. **Allocate Memory**: Click "Allocate Memory" to reserve memory space for your text
3. **Observe**: See the memory address, content, size, and byte representation
4. **Deallocate**: Click "Deallocate Memory" to free the allocated space
5. **Repeat**: Try different text lengths and observe how memory usage changes

## Architecture

The application consists of three main components:

- **engine.swift**: Core memory management logic with `MemoryManager` class
- **ui.swift**: SwiftUI-based user interface with educational visualizations
- **MemVi.swift**: Application entry point

The `MemoryManager` uses Swift's `UnsafeMutablePointer` to demonstrate real memory allocation, making it an authentic educational tool for understanding low-level memory concepts.

## Safety Note

This tool is designed for educational purposes and properly manages memory allocation and deallocation to prevent memory leaks and crashes.