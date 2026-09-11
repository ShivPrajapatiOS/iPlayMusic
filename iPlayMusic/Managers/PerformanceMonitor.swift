//
//  PerformanceMonitor.swift
//  iPlayMusic
//
//  Created by Shiv on 05/09/26.
//

import Foundation
import SwiftUI
import Combine

final class PerformanceMonitor: ObservableObject {
    static let shared: PerformanceMonitor = .init()

    @Published var cpuUsage: Double = 0        // Percentage (0-100+, multi-core hone par 100 se zyada bhi ho sakta hai)
    @Published var memoryUsageMB: Double = 0   // App ka resident memory in MB

    private var timer: Timer?
    private var previousCPUTicks: (system: UInt64, user: UInt64)?

    private init() {}

    func start() {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.sample()
        }
        RunLoop.main.add(timer!, forMode: .common)
        sample() // pehli reading turant le lo
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func sample() {
        cpuUsage = Self.currentCPUUsage()
        memoryUsageMB = Self.currentMemoryUsageMB()
    }

    // MARK: - CPU Usage (sab threads ka total, task_threads se)
    private static func currentCPUUsage() -> Double {
        var kr: kern_return_t

        var thread_list: thread_act_array_t?
        var thread_count: mach_msg_type_number_t = 0

        kr = task_threads(mach_task_self_, &thread_list, &thread_count)
        guard kr == KERN_SUCCESS, let threadList = thread_list else { return 0 }

        var totalUsageOfCPU: Double = 0.0

        for i in 0..<Int(thread_count) {
            var thread_info_count = mach_msg_type_number_t(THREAD_INFO_MAX)
            var thinfo = [integer_t](repeating: 0, count: Int(thread_info_count))

            let infoResult = thinfo.withUnsafeMutableBufferPointer { ptr -> kern_return_t in
                thread_info(threadList[i], thread_flavor_t(THREAD_BASIC_INFO), ptr.baseAddress!, &thread_info_count)
            }

            if infoResult == KERN_SUCCESS {
                let threadBasicInfo = withUnsafePointer(to: &thinfo) {
                    $0.withMemoryRebound(to: thread_basic_info.self, capacity: 1) { $0.pointee }
                }
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
                }
            }
        }

        let threadListSize = vm_size_t(Int(thread_count) * MemoryLayout<thread_t>.stride)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadList), threadListSize)

        return totalUsageOfCPU
    }

    // MARK: - Memory Usage (resident size)
    private static func currentMemoryUsageMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / 1024.0 / 1024.0
    }
}

struct DebugOverlayView: View {
    @StateObject private var monitor: PerformanceMonitor = .shared
    @StateObject private var player: PlayerManager = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(cpuColor)
                    .frame(width: 8, height: 8)
                Text("Decoder: \(player.decoderType.rawValue)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            Text("CPU: \(String(format: "%.1f", monitor.cpuUsage))%")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
            Text("RAM: \(String(format: "%.1f", monitor.memoryUsageMB)) MB")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(.white)
        .padding(10)
        .background(Color.black.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onAppear { monitor.start() }
        .onDisappear { monitor.stop() }
    }

    private var cpuColor: Color {
        switch monitor.cpuUsage {
        case ..<30: return .green
        case 30..<70: return .yellow
        default: return .red
        }
    }
}

#Preview {
    DebugOverlayView()
        .padding()
        .background(Color.gray)
}
