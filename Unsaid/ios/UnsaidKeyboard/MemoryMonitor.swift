import Foundation
import os.log

class MemoryMonitor {
    static let shared = MemoryMonitor()
    private let log = OSLog(subsystem: "com.unsaid.keyboard", category: "Memory")
    
    private init() {}
    
    func logMemoryUsage(context: String) {
        let memoryUsage = getCurrentMemoryUsage()
        os_log("🧠 Memory Usage [%{public}@]: %.2f MB", log: log, type: .info, context, memoryUsage)
        
        // Alert if memory usage is high
        if memoryUsage > 20.0 { // 20MB threshold
            os_log("⚠️ High Memory Usage [%{public}@]: %.2f MB", log: log, type: .error, context, memoryUsage)
        }
    }
    
    func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
    
    func forceMemoryCleanup() {
        // Force garbage collection
        autoreleasepool {
            // Trigger memory cleanup
        }
        
        // Log memory after cleanup
        logMemoryUsage(context: "After Cleanup")
    }
}
