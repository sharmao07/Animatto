import Foundation
import AppKit
import Darwin
import IOKit
import IOKit.ps

// MARK: - Mach System & Process Telemetry

enum MachQueryError: Error, CustomStringConvertible {
    case kernelFailure(flavor: String, code: kern_return_t)
    var description: String {
        switch self {
        case .kernelFailure(let flavor, let code):
            let errStr = String(cString: mach_error_string(code))
            return "Mach kernel query failed for flavor '\(flavor)': code \(code) (\(errStr))"
        }
    }
}

struct SystemInfo {
    let model: String
    let cpuBrand: String
    let totalCores: Int
    let ramGB: Double
    let macOSProductVersion: String
    
    static func query() -> SystemInfo {
        func sysctlString(_ name: String) -> String {
            var size = 0
            sysctlbyname(name, nil, &size, nil, 0)
            guard size > 0 else { return "" }
            var buf = [CChar](repeating: 0, count: size)
            sysctlbyname(name, &buf, &size, nil, 0)
            return String(cString: buf)
        }
        
        let modelStr = sysctlString("hw.model")
        let cpuStr = sysctlString("machdep.cpu.brand_string")
        
        var totalCores: Int32 = 0
        var size = MemoryLayout<Int32>.size
        sysctlbyname("hw.ncpu", &totalCores, &size, nil, 0)
        
        var memBytes: UInt64 = 0
        size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &memBytes, &size, nil, 0)
        let ramGB = Double(memBytes) / (1024.0 * 1024.0 * 1024.0)
        
        let productVer = sysctlString("kern.osproductversion")
        
        return SystemInfo(
            model: modelStr.isEmpty ? "Mac" : modelStr,
            cpuBrand: cpuStr.isEmpty ? "Apple Silicon" : cpuStr,
            totalCores: Int(totalCores),
            ramGB: ramGB,
            macOSProductVersion: productVer.isEmpty ? ProcessInfo.processInfo.operatingSystemVersionString : productVer
        )
    }
}

struct ProcessMemoryMetrics {
    let physicalFootprintMB: Double
    let residentRSSMB: Double
    
    static func sample() -> ProcessMemoryMetrics {
        var vmInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / 4)
        let kr = withUnsafeMutablePointer(to: &vmInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        var basicInfo = mach_task_basic_info()
        var basicCount = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)
        let krBasic = withUnsafeMutablePointer(to: &basicInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &basicCount)
            }
        }
        
        let physMB = (kr == KERN_SUCCESS) ? Double(vmInfo.phys_footprint) / (1024.0 * 1024.0) : 0.0
        let rssMB = (krBasic == KERN_SUCCESS) ? Double(basicInfo.resident_size) / (1024.0 * 1024.0) : 0.0
        return ProcessMemoryMetrics(physicalFootprintMB: physMB, residentRSSMB: rssMB)
    }
}

func sampleCpuTimes() -> (user: TimeInterval, system: TimeInterval) {
    var threadList: thread_act_array_t?
    var threadCount: mach_msg_type_number_t = 0
    let kr = task_threads(mach_task_self_, &threadList, &threadCount)
    guard kr == KERN_SUCCESS, let threads = threadList else { return (0, 0) }
    
    var totalUser: TimeInterval = 0
    var totalSystem: TimeInterval = 0
    
    for i in 0..<Int(threadCount) {
        var threadInfo = thread_basic_info()
        var infoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
        let krInfo = withUnsafeMutablePointer(to: &threadInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) { intPtr in
                thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), intPtr, &infoCount)
            }
        }
        if krInfo == KERN_SUCCESS {
            totalUser += Double(threadInfo.user_time.seconds) + Double(threadInfo.user_time.microseconds) / 1_000_000.0
            totalSystem += Double(threadInfo.system_time.seconds) + Double(threadInfo.system_time.microseconds) / 1_000_000.0
        }
    }
    vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(threadCount * UInt32(MemoryLayout<thread_t>.stride)))
    return (totalUser, totalSystem)
}

// MARK: - Benchmark Result Structure

struct AquariumBenchmarkResult {
    let companionCount: Int
    let durationSeconds: Double
    let totalTicks: Int
    let averageTicksPerSec: Double
    let avgCpuPercent: Double
    let peakCpuPercent: Double
    let residentRSSMB: Double
    let physicalFootprintMB: Double
    let cacheMemoryBytes: Int
    let preloadedFrameCount: Int
    let budgetCpuPass: Bool
    let budgetRamPass: Bool
}

// MARK: - Benchmark Runner

@main
struct AquariumBenchmarkSuite {
    static func main() {
        print("================================================================================")
        print("          ANIMATTO AQUARIUM MODE — STAGE 4.8 BENCHMARK SUITE                    ")
        print("================================================================================")
        
        let sys = SystemInfo.query()
        print("Hardware: \(sys.model) (\(sys.cpuBrand), \(sys.totalCores) cores), \(String(format: "%.1f", sys.ramGB)) GB RAM")
        print("macOS Version: \(sys.macOSProductVersion)")
        print("Nominal Simulation Cadence: 30.0 Hz (Balanced Mode)")
        print("Performance Budgets: CPU < 2.5%, Resident Memory ≤ 35.0 MB")
        print("--------------------------------------------------------------------------------\n")
        
        // Warmup: Preload sprite assets for all species to stabilize cache
        print("Warmup: Loading species animation assets...")
        let speciesFolders = ["Sunfin", "Puffer", "Tetra", "HermitCrab"]
        var loadedCount = 0
        for folder in speciesFolders {
            if let dir = AquariumDirectoryResolver.resolveAquariumSpeciesDirectory(speciesFolder: folder) {
                if let manifest = try? AnimationAssetCache.shared.manifest(for: dir) {
                    for (stateName, stateConfig) in manifest.states {
                        for frameIdx in 0..<stateConfig.frameCount {
                            if let _ = AnimationAssetCache.shared.frame(for: dir, state: stateName, frameIndex: frameIdx) {
                                loadedCount += 1
                            }
                        }
                    }
                }
            }
        }
        print("Preloaded \(loadedCount) total aquatic sprite frames into AnimationAssetCache.shared.\n")
        
        let testConfigs = [1, 5, 10]
        var results: [AquariumBenchmarkResult] = []
        
        for count in testConfigs {
            print(">>> Running Benchmark: \(count) Companion(s) across 15.0 seconds...")
            let result = runBenchmark(companionCount: count, duration: 15.0)
            results.append(result)
            
            print(String(format: "    Ticks: %d (%.2f Hz), CPU: %.2f%% (Peak: %.2f%%), RSS: %.2f MB, Footprint: %.2f MB, Cache: %.2f MB",
                         result.totalTicks,
                         result.averageTicksPerSec,
                         result.avgCpuPercent,
                         result.peakCpuPercent,
                         result.residentRSSMB,
                         result.physicalFootprintMB,
                         Double(result.cacheMemoryBytes) / (1024.0 * 1024.0)))
            print(String(format: "    Budget Check: CPU < 2.5%% -> %@ | RAM ≤ 35.0 MB -> %@",
                         result.budgetCpuPass ? "PASS" : "FAIL",
                         result.budgetRamPass ? "PASS" : "FAIL"))
            print("")
        }
        
        print("================================================================================")
        print("                         FINAL BENCHMARK SUMMARY                                ")
        print("================================================================================")
        print("| Companions | Simulation Cadence | Avg CPU (%) | Peak CPU (%) | Resident RSS (MB) | Physical Footprint (MB) | Cache Footprint | CPU Budget (<2.5%) | RAM Budget (≤35MB) |")
        print("|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|")
        
        for r in results {
            print(String(format: "| %d | %.2f Hz | %.2f%% | %.2f%% | %.2f MB | %.2f MB | %.2f MB (%d frames) | %@ | %@ |",
                         r.companionCount,
                         r.averageTicksPerSec,
                         r.avgCpuPercent,
                         r.peakCpuPercent,
                         r.residentRSSMB,
                         r.physicalFootprintMB,
                         Double(r.cacheMemoryBytes) / (1024.0 * 1024.0),
                         r.preloadedFrameCount,
                         r.budgetCpuPass ? "✅ PASS" : "❌ FAIL",
                         r.budgetRamPass ? "✅ PASS" : "❌ FAIL"))
        }
        print("================================================================================\n")
    }
    
    static func runBenchmark(companionCount: Int, duration: Double) -> AquariumBenchmarkResult {
        let manager = AquariumManager(initialSettings: AquariumSettings())
        manager.updateBounds(dimensions: CGSize(width: 720, height: 480))
        manager.activeCompanions.removeAll()
        
        // Spawn companions according to companionCount
        // 1: Finny
        // 5: Finny, Pip, Glow 1, Glow 2, Barnaby
        // 10: Finny, Pip, 6 schooling Tetras, 2 Barnabies
        if companionCount == 1 {
            let finny = AquaticCompanionInstance(profile: .sunfin)
            manager.addCompanion(finny)
        } else if companionCount == 5 {
            let finny = AquaticCompanionInstance(profile: .sunfin)
            let pip = AquaticCompanionInstance(profile: .puffer)
            let glow1 = AquaticCompanionInstance(profile: .tetra)
            let glow2 = AquaticCompanionInstance(profile: .tetra)
            glow2.displayName = "Glow 2"
            let barnaby = AquaticCompanionInstance(profile: .hermitCrab)
            
            manager.addCompanion(finny)
            manager.addCompanion(pip)
            manager.addCompanion(glow1)
            manager.addCompanion(glow2)
            manager.addCompanion(barnaby)
        } else {
            // 10 companions
            let finny = AquaticCompanionInstance(profile: .sunfin)
            let pip = AquaticCompanionInstance(profile: .puffer)
            manager.addCompanion(finny)
            manager.addCompanion(pip)
            
            for i in 1...6 {
                let tetra = AquaticCompanionInstance(
                    profile: .tetra,
                    initialState: AquaticEntityState(
                        position: AquaticVector3D(x: 200.0 + Double(i * 30), y: 220.0 + Double(i * 10), z: 0.65)
                    )
                )
                tetra.displayName = "Glow \(i)"
                manager.addCompanion(tetra)
            }
            
            let barnaby1 = AquaticCompanionInstance(profile: .hermitCrab)
            let barnaby2 = AquaticCompanionInstance(profile: .hermitCrab)
            barnaby2.displayName = "Barnaby 2"
            manager.addCompanion(barnaby1)
            manager.addCompanion(barnaby2)
        }
        
        let dt = 1.0 / 30.0 // 30 Hz nominal
        let totalTargetTicks = Int(duration / dt)
        
        _ = ProcessMemoryMetrics.sample()
        let cpuBefore = sampleCpuTimes()
        let startUptime = ProcessInfo.processInfo.systemUptime
        
        var peakCpu: Double = 0.0
        var windowCpuSamples: [Double] = []
        var lastSampleUptime = startUptime
        var lastSampleCpu = cpuBefore
        
        var tickCount = 0
        for tick in 0..<totalTargetTicks {
            // Periodic interactive feeding event every 4.0 seconds
            if tick % 120 == 0 {
                manager.feedAt(point: CGPoint(x: 360, y: 120))
            }
            
            // Advance food pellets
            var pelletIdx = 0
            while pelletIdx < manager.foodPellets.count {
                if !manager.foodPellets[pelletIdx].isSettled {
                    manager.foodPellets[pelletIdx].age += dt
                    manager.foodPellets[pelletIdx].wobblePhase += dt * manager.foodPellets[pelletIdx].wobbleFreq * (.pi * 2.0)
                    let wobbleOffset = sin(manager.foodPellets[pelletIdx].wobblePhase) * 12.0 * dt
                    manager.foodPellets[pelletIdx].position.x += wobbleOffset
                    manager.foodPellets[pelletIdx].position.y += manager.foodPellets[pelletIdx].velocity.y * dt
                    if manager.foodPellets[pelletIdx].position.y <= manager.currentBounds.minY + 6.0 {
                        manager.foodPellets[pelletIdx].position.y = manager.currentBounds.minY + 6.0
                        manager.foodPellets[pelletIdx].velocity = .zero
                        manager.foodPellets[pelletIdx].isSettled = true
                    }
                    pelletIdx += 1
                } else {
                    manager.foodPellets[pelletIdx].dissolveProgress += dt / 15.0
                    if manager.foodPellets[pelletIdx].dissolveProgress >= 1.0 {
                        manager.foodPellets.remove(at: pelletIdx)
                    } else {
                        pelletIdx += 1
                    }
                }
            }
            
            // Step AI for each companion
            for companion in manager.activeCompanions {
                companion.stepAI(
                    bounds: manager.currentBounds,
                    allCompanions: manager.activeCompanions,
                    pellets: &manager.foodPellets,
                    cursorLocation: nil,
                    dt: dt
                )
            }
            
            tickCount += 1
            
            // Sample window CPU every 1.0s (30 ticks)
            if tick > 0 && tick % 30 == 0 {
                let nowUptime = ProcessInfo.processInfo.systemUptime
                let nowCpu = sampleCpuTimes()
                let dWall = nowUptime - lastSampleUptime
                let dCpu = (nowCpu.user + nowCpu.system) - (lastSampleCpu.user + lastSampleCpu.system)
                if dWall > 0 {
                    let pct = (dCpu / dWall) * 100.0
                    windowCpuSamples.append(pct)
                    if pct > peakCpu { peakCpu = pct }
                }
                lastSampleUptime = nowUptime
                lastSampleCpu = nowCpu
            }
            
            // Accurate simulation timing throttle
            usleep(UInt32(dt * 1_000_000.0))
        }
        
        let endUptime = ProcessInfo.processInfo.systemUptime
        let cpuAfter = sampleCpuTimes()
        let memAfter = ProcessMemoryMetrics.sample()
        
        let totalWall = endUptime - startUptime
        let totalCpuSeconds = (cpuAfter.user + cpuAfter.system) - (cpuBefore.user + cpuBefore.system)
        let overallCpuPercent = totalWall > 0 ? (totalCpuSeconds / totalWall) * 100.0 : 0.0
        let avgTicksPerSec = totalWall > 0 ? Double(tickCount) / totalWall : 30.0
        
        let cacheBytes = AnimationAssetCache.shared.currentCostInBytes
        let frameCount = AnimationAssetCache.shared.cachedFrameCount
        
        manager.invalidate()
        
        return AquariumBenchmarkResult(
            companionCount: companionCount,
            durationSeconds: totalWall,
            totalTicks: tickCount,
            averageTicksPerSec: avgTicksPerSec,
            avgCpuPercent: overallCpuPercent,
            peakCpuPercent: max(peakCpu, overallCpuPercent),
            residentRSSMB: memAfter.residentRSSMB,
            physicalFootprintMB: memAfter.physicalFootprintMB,
            cacheMemoryBytes: cacheBytes,
            preloadedFrameCount: frameCount,
            budgetCpuPass: overallCpuPercent < 2.5,
            budgetRamPass: memAfter.residentRSSMB <= 35.0
        )
    }
}
