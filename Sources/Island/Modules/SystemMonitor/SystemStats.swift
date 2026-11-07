import Foundation
import Observation
import Darwin

/// Polls CPU and memory usage via Mach host APIs. Cheap (~1s timer), no
/// external process spawning (unlike shelling out to `top`).
@Observable
final class SystemStats {
    var cpuUsage: Double = 0      // 0...100
    var memoryUsedGB: Double = 0
    var memoryTotalGB: Double = 0
    var diskUsedGB: Double = 0
    var diskTotalGB: Double = 0

    private var timer: Timer?
    private var previousCPUTicks: host_cpu_load_info?

    init() {
        memoryTotalGB = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func refresh() {
        updateCPU()
        updateMemory()
        updateDisk()
    }

    private func updateDisk() {
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]),
              let total = values.volumeTotalCapacity,
              let available = values.volumeAvailableCapacity else { return }

        diskTotalGB = Double(total) / 1_073_741_824
        diskUsedGB = Double(total - available) / 1_073_741_824
    }

    private func updateCPU() {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)
        var load = host_cpu_load_info()

        let result = withUnsafeMutablePointer(to: &load) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { intPtr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, intPtr, &size)
            }
        }
        guard result == KERN_SUCCESS else { return }

        if let previous = previousCPUTicks {
            let userDelta = Double(load.cpu_ticks.0 - previous.cpu_ticks.0)
            let systemDelta = Double(load.cpu_ticks.1 - previous.cpu_ticks.1)
            let idleDelta = Double(load.cpu_ticks.2 - previous.cpu_ticks.2)
            let niceDelta = Double(load.cpu_ticks.3 - previous.cpu_ticks.3)

            let totalDelta = userDelta + systemDelta + idleDelta + niceDelta
            if totalDelta > 0 {
                cpuUsage = ((userDelta + systemDelta + niceDelta) / totalDelta) * 100
            }
        }
        previousCPUTicks = load
    }

    private func updateMemory() {
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        var stats = vm_statistics64()

        let result = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &size)
            }
        }
        guard result == KERN_SUCCESS else { return }

        let pageSize = Double(vm_kernel_page_size)
        let usedPages = Double(stats.active_count + stats.wire_count + stats.compressor_page_count)
        memoryUsedGB = (usedPages * pageSize) / 1_073_741_824
    }
}
