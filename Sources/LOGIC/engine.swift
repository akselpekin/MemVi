import Foundation

// MARK: - Data Model

enum DataType: String, CaseIterable {
    case string = "String"
    case integer = "Integer"
    case float = "Float"
    case array = "Array"
    
    var byteSize: Int {
        switch self {
        case .string: return 0 // Variable size
        case .integer: return 8 // 64-bit integer
        case .float: return 8 // 64-bit double
        case .array: return 0 // Variable size
        }
    }
}

struct MemoryBlock: Identifiable {
    let id = UUID()
    let address: String
    let content: String
    let dataType: DataType
    let size: Int
    let allocatedAt: Date
    
    var hexAddress: String {
        if let range = address.range(of: "0x") {
            return String(address[range.lowerBound...])
        }
        return address
    }
    
    var bytesRepresentation: [UInt8] {
        switch dataType {
        case .string:
            return Array(content.utf8) + [0]
        case .integer:
            if let intValue = Int64(content) {
                return withUnsafeBytes(of: intValue.bigEndian) { Array($0) }
            }
            return Array(content.utf8) + [0]
        case .float:
            if let floatValue = Double(content) {
                return withUnsafeBytes(of: floatValue.bitPattern.bigEndian) { Array($0) }
            }
            return Array(content.utf8) + [0]
        case .array:
            return Array(content.utf8) + [0]
        }
    }
}

struct MemoryStatistics {
    var totalAllocations: Int = 0
    var currentAllocations: Int = 0
    var totalBytesAllocated: Int = 0
    var currentBytesAllocated: Int = 0
    var peakBytesAllocated: Int = 0
    var allocationHistory: [MemoryBlock] = []
}

// MARK: - Memory Manager

@MainActor
final class MemoryManager: ObservableObject {
    static let shared = MemoryManager()

    private init() {}

    private var allocatedPointers: [UUID: UnsafeMutablePointer<UInt8>] = [:]
    @Published private(set) var activeBlocks: [MemoryBlock] = []
    @Published private(set) var statistics = MemoryStatistics()

    func allocateMemory(_ content: String, dataType: DataType) -> MemoryBlock? {
        guard validateInput(content, for: dataType) else {
            return nil
        }
        
        let processedContent = preprocessContent(content, for: dataType)
        let size = calculateSize(for: processedContent, dataType: dataType)
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        
        switch dataType {
        case .string:
            writeStringData(processedContent, to: buffer)
        case .integer:
            writeIntegerData(processedContent, to: buffer)
        case .float:
            writeFloatData(processedContent, to: buffer)
        case .array:
            writeArrayData(processedContent, to: buffer)
        }

        let newBlock = MemoryBlock(
            address: "\(buffer)", 
            content: processedContent,
            dataType: dataType,
            size: size,
            allocatedAt: Date()
        )
        
        allocatedPointers[newBlock.id] = buffer
        activeBlocks.append(newBlock)
        
        updateStatisticsForAllocation(newBlock)

        return newBlock
    }
    
    func deallocateMemory(_ blockId: UUID) {
        guard let pointer = allocatedPointers[blockId],
              let blockIndex = activeBlocks.firstIndex(where: { $0.id == blockId }) else {
            return
        }
        
        let block = activeBlocks[blockIndex]
        
        pointer.deallocate()
        allocatedPointers.removeValue(forKey: blockId)
        activeBlocks.remove(at: blockIndex)
        
        updateStatisticsForDeallocation(block)
    }
    
    func deallocateAllMemory() {
        for (_, pointer) in allocatedPointers {
            pointer.deallocate()
        }
        allocatedPointers.removeAll()
        
        statistics.currentAllocations = 0
        statistics.currentBytesAllocated = 0
        activeBlocks.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func validateInput(_ content: String, for dataType: DataType) -> Bool {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        
        switch dataType {
        case .string:
            return true
            
        case .integer:
            return Int64(content.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
            
        case .float:
            return Double(content.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
            
        case .array:
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let cleanContent = trimmed.hasPrefix("[") && trimmed.hasSuffix("]") 
                ? String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                : trimmed
            
            let elements = cleanContent.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            
            guard !elements.isEmpty && !elements.contains("") else {
                return false
            }
            
            return elements.allSatisfy { element in
                if Int64(element) != nil {
                    return true
                }
                if Double(element) != nil {
                    return true
                }
                return !element.isEmpty && !element.contains(" ") && element.allSatisfy { char in
                    char.isLetter || char.isNumber || "_-".contains(char)
                }
            }
        }
    }
    
    private func preprocessContent(_ content: String, for dataType: DataType) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch dataType {
        case .string:
            return trimmed
            
        case .integer:
            if let intValue = Int64(trimmed) {
                return String(intValue)
            }
            return "0"
            
        case .float:
            if let floatValue = Double(trimmed) {
                return String(floatValue)
            }
            return "0.0"
            
        case .array:
            var cleaned = trimmed
            if cleaned.hasPrefix("[") && cleaned.hasSuffix("]") {
                cleaned = String(cleaned.dropFirst().dropLast())
            }
            return "[\(cleaned)]"
        }
    }
    
    private func calculateSize(for content: String, dataType: DataType) -> Int {
        switch dataType {
        case .string:
            return content.utf8.count + 1
        case .integer:
            return 8
        case .float:
            return 8
        case .array:
            return content.utf8.count + 1
        }
    }
    
    private func writeStringData(_ content: String, to buffer: UnsafeMutablePointer<UInt8>) {
        for (i, byte) in content.utf8.enumerated() {
            buffer[i] = byte
        }
        buffer[content.utf8.count] = 0
    }
    
    private func writeIntegerData(_ content: String, to buffer: UnsafeMutablePointer<UInt8>) {
        let intValue = Int64(content) ?? 0
        let bytes = withUnsafeBytes(of: intValue.bigEndian) { Array($0) }
        for (i, byte) in bytes.enumerated() {
            buffer[i] = byte
        }
    }
    
    private func writeFloatData(_ content: String, to buffer: UnsafeMutablePointer<UInt8>) {
        let floatValue = Double(content) ?? 0.0
        let bytes = withUnsafeBytes(of: floatValue.bitPattern.bigEndian) { Array($0) }
        for (i, byte) in bytes.enumerated() {
            buffer[i] = byte
        }
    }
    
    private func writeArrayData(_ content: String, to buffer: UnsafeMutablePointer<UInt8>) {
        writeStringData(content, to: buffer)
    }
    
    private func updateStatisticsForAllocation(_ block: MemoryBlock) {
        statistics.totalAllocations += 1
        statistics.currentAllocations += 1
        statistics.totalBytesAllocated += block.size
        statistics.currentBytesAllocated += block.size
        statistics.peakBytesAllocated = max(statistics.peakBytesAllocated, statistics.currentBytesAllocated)
        statistics.allocationHistory.append(block)
    }
    
    private func updateStatisticsForDeallocation(_ block: MemoryBlock) {
        statistics.currentAllocations -= 1
        statistics.currentBytesAllocated -= block.size
    }

    deinit {
        // Note: Cannot access MainActor properties from deinit
        // Memory cleanup will happen when the process ends
    }
}