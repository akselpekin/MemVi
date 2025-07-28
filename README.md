# MemVi - Memory Visualizer

An educational GUI tool for computer architecture learning, focusing on memory allocation and visualization.

## Features

- **Interactive Memory Allocation**: Users can input text and see how it's stored in system memory
- **Real Memory Addresses**: Shows actual memory addresses where data is allocated
- **Byte-level Visualization**: Displays hexadecimal representation of stored data
- **Memory Management**: Allocate and deallocate memory to understand memory lifecycle

## Installation 

```diff
+Refer to releases section.
```

## Building and Running (source)

```diff
+Requirements:
-macOS 15.0+
-Swift 6.1+
```

### Build & Run the project:
```bash
cd /path
swift run
```

## Architecture

The application consists of three main components:

- **engine.swift**: Core memory management logic with `MemoryManager` class
- **ui.swift**: SwiftUI-based user interface with educational visualizations
- **MemVi.swift**: Application entry point

The `MemoryManager` uses Swift's `UnsafeMutablePointer` to demonstrate real memory allocation, making it an authentic educational tool for understanding low-level memory concepts.

## Safety Note

*This tool is designed for educational purposes and properly manages memory allocation and deallocation to prevent memory leaks and crashes.*