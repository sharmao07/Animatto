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
    let performanceCores: Int
    let efficiencyCores: Int
    let ramGB: Double
    let macOSProductVersion: String
    let macOSBuildVersion: String
    let darwinKernelVersion: String
    
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
        
        var pCores: Int32 = 0
        size = MemoryLayout<Int32>.size
        sysctlbyname("hw.perflevel0.logicalcpu", &pCores, &size, nil, 0)
        
        var eCores: Int32 = 0
        size = MemoryLayout<Int32>.size
        sysctlbyname("hw.perflevel1.logicalcpu", &eCores, &size, nil, 0)
        
        var memBytes: UInt64 = 0
        size = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &memBytes, &size, nil, 0)
        let ramGB = Double(memBytes) / (1024.0 * 1024.0 * 1024.0)
        
        let productVer = sysctlString("kern.osproductversion")
        let buildVer = sysctlString("kern.osversion")
        let kernelVer = sysctlString("kern.osrelease")
        
        return SystemInfo(
            model: modelStr.isEmpty ? "Mac" : modelStr,
            cpuBrand: cpuStr.isEmpty ? "Apple Silicon" : cpuStr,
            totalCores: Int(totalCores),
            performanceCores: Int(pCores),
            efficiencyCores: Int(eCores),
            ramGB: ramGB,
            macOSProductVersion: productVer.isEmpty ? ProcessInfo.processInfo.operatingSystemVersionString : productVer,
            macOSBuildVersion: buildVer.isEmpty ? "Unknown" : buildVer,
            darwinKernelVersion: kernelVer.isEmpty ? "Unknown" : kernelVer
        )
    }
}

struct BatteryStatus {
    let hasBattery: Bool
    let isCharging: Bool
    let externalConnected: Bool
    let batteryPercentage: Double
    let powerSourceState: String
    let voltageMilliVolts: Int
    let cycleCount: Int
    let temperatureCelsius: Double
    
    static func query() -> BatteryStatus {
        var hasBat = false
        var isCharging = false
        var extConnected = true
        var pct = 100.0
        var stateStr = "AC Power"
        
        if let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
           let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] {
            for ps in sources {
                if let desc = IOPSGetPowerSourceDescription(snapshot, ps)?.takeUnretainedValue() as? [String: Any] {
                    hasBat = true
                    if let cur = desc[kIOPSCurrentCapacityKey] as? Int,
                       let maxCap = desc[kIOPSMaxCapacityKey] as? Int, maxCap > 0 {
                        pct = (Double(cur) / Double(maxCap)) * 100.0
                    }
                    if let charging = desc[kIOPSIsChargingKey] as? Bool {
                        isCharging = charging
                    }
                    if let state = desc[kIOPSPowerSourceStateKey] as? String {
                        stateStr = state
                        extConnected = (state == kIOPSACPowerValue)
                    }
                }
            }
        }
        
        var volt = 0
        var cycles = 0
        var tempC = 0.0
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        if service != 0 {
            var props: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
               let dict = props?.takeRetainedValue() as? [String: Any] {
                volt = dict["Voltage"] as? Int ?? 0
                cycles = dict["CycleCount"] as? Int ?? 0
                if let rawTemp = dict["Temperature"] as? Int {
                    tempC = Double(rawTemp) / 100.0
                }
            }
            IOObjectRelease(service)
        }
        
        return BatteryStatus(
            hasBattery: hasBat,
            isCharging: isCharging,
            externalConnected: extConnected,
            batteryPercentage: pct,
            powerSourceState: stateStr,
            voltageMilliVolts: volt,
            cycleCount: cycles,
            temperatureCelsius: tempC
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
            ptr.withMemoryRebound(to: integer_t.self, capacity: 1) {
                thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
            }
        }
        if krInfo == KERN_SUCCESS {
            let uSec = Double(threadInfo.user_time.seconds) + Double(threadInfo.user_time.microseconds) / 1_000_000.0
            let sSec = Double(threadInfo.system_time.seconds) + Double(threadInfo.system_time.microseconds) / 1_000_000.0
            totalUser += uSec
            totalSystem += sSec
        }
    }
    vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(threadCount * UInt32(MemoryLayout<thread_t>.size)))
    return (totalUser, totalSystem)
}

struct MachTaskPowerSnapshot {
    let taskEnergy: UInt64
    let taskInterruptWakeups: UInt64
    let taskPlatformIdleWakeups: UInt64
    let taskTimerWakeups: UInt64
    
    static func sample() -> MachTaskPowerSnapshot {
        var powerInfo = task_power_info_v2()
        var count = mach_msg_type_number_t(MemoryLayout<task_power_info_v2>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &powerInfo) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_POWER_INFO_V2), $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else {
            return MachTaskPowerSnapshot(taskEnergy: 0, taskInterruptWakeups: 0, taskPlatformIdleWakeups: 0, taskTimerWakeups: 0)
        }
        #if arch(arm64) || arch(arm)
        let energy = powerInfo.task_energy
        #else
        let energy: UInt64 = 0
        #endif
        return MachTaskPowerSnapshot(
            taskEnergy: energy,
            taskInterruptWakeups: powerInfo.cpu_energy.task_interrupt_wakeups,
            taskPlatformIdleWakeups: powerInfo.cpu_energy.task_platform_idle_wakeups,
            taskTimerWakeups: powerInfo.cpu_energy.task_timer_wakeups_bin_1 + powerInfo.cpu_energy.task_timer_wakeups_bin_2
        )
    }
}

// MARK: - Scenario Measurement Data

struct ScenarioBenchmarkResult {
    let scenarioName: String
    let durationSeconds: Double
    let avgCpuPercent: Double
    let peakCpuPercent: Double
    let physicalFootprintMB: Double
    let residentRSSMB: Double
    let measuredTickRate: Double
    let taskEnergyRate: Double
    let interruptWakeupsRate: Double
    let additionalNotes: String
}

// MARK: - Phase 6 Benchmark Harness

func runScenario(
    name: String,
    duration: Double,
    setup: () -> Void,
    step: (_ dt: Double) -> Void,
    teardown: () -> Void
) -> ScenarioBenchmarkResult {
    setup()
    
    // Warm-up 0.5s
    let warmStart = ProcessInfo.processInfo.systemUptime
    while ProcessInfo.processInfo.systemUptime - warmStart < 0.5 {
        step(0.033)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
    }
    
    let initialMem = ProcessMemoryMetrics.sample()
    let initialPower = MachTaskPowerSnapshot.sample()
    let initialCpu = sampleCpuTimes()
    let startTime = ProcessInfo.processInfo.systemUptime
    
    var peakCpu: Double = 0.0
    var samples: [Double] = []
    var lastSampleTime = startTime
    var lastSampleCpu = initialCpu
    var stepCount = 0
    
    while ProcessInfo.processInfo.systemUptime - startTime < duration {
        step(0.033)
        stepCount += 1
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.02))
        
        let now = ProcessInfo.processInfo.systemUptime
        let elapsedSample = now - lastSampleTime
        if elapsedSample >= 0.25 {
            let currentCpu = sampleCpuTimes()
            let cpuDelta = (currentCpu.user + currentCpu.system) - (lastSampleCpu.user + lastSampleCpu.system)
            let pct = (cpuDelta / elapsedSample) * 100.0
            samples.append(pct)
            if pct > peakCpu { peakCpu = pct }
            lastSampleTime = now
            lastSampleCpu = currentCpu
        }
    }
    
    let totalTime = ProcessInfo.processInfo.systemUptime - startTime
    let finalCpu = sampleCpuTimes()
    let finalPower = MachTaskPowerSnapshot.sample()
    let finalMem = ProcessMemoryMetrics.sample()
    
    let totalCpuDelta = (finalCpu.user + finalCpu.system) - (initialCpu.user + initialCpu.system)
    let avgCpu = (totalCpuDelta / totalTime) * 100.0
    
    let energyDelta = Double(finalPower.taskEnergy > initialPower.taskEnergy ? finalPower.taskEnergy - initialPower.taskEnergy : 0)
    let energyRate = energyDelta / totalTime
    
    let wakeupsDelta = Double(finalPower.taskInterruptWakeups > initialPower.taskInterruptWakeups ? finalPower.taskInterruptWakeups - initialPower.taskInterruptWakeups : 0)
    let wakeupsRate = wakeupsDelta / totalTime
    
    let tickRate = Double(stepCount) / totalTime
    
    teardown()
    
    return ScenarioBenchmarkResult(
        scenarioName: name,
        durationSeconds: totalTime,
        avgCpuPercent: avgCpu,
        peakCpuPercent: peakCpu,
        physicalFootprintMB: finalMem.physicalFootprintMB,
        residentRSSMB: finalMem.residentRSSMB,
        measuredTickRate: tickRate,
        taskEnergyRate: energyRate,
        interruptWakeupsRate: wakeupsRate,
        additionalNotes: "Mem Δ: \(String(format: "%+.1f MB", finalMem.physicalFootprintMB - initialMem.physicalFootprintMB))"
    )
}

// MARK: - Main Execution

@main
struct BenchmarkRunner {
    static func main() {
        let sys = SystemInfo.query()
        let batt = BatteryStatus.query()

        print("================================================================================")
        print(" ANIMATTO PHASE 6 FULL-SYSTEM PERFORMANCE BENCHMARK (7 SCENARIOS)")
        print(" Platform: \(sys.model) | \(sys.cpuBrand) (\(sys.totalCores) cores: \(sys.performanceCores)P / \(sys.efficiencyCores)E) | \(String(format: "%.1f GB", sys.ramGB)) RAM")
        print(" OS: macOS \(sys.macOSProductVersion) (\(sys.macOSBuildVersion)), Darwin \(sys.darwinKernelVersion)")
        print(" Battery: \(batt.hasBattery ? "\(String(format: "%.1f%%", batt.batteryPercentage)) (\(batt.powerSourceState), \(batt.voltageMilliVolts) mV, \(batt.temperatureCelsius) °C)" : "Direct AC Line Power")")
        print("================================================================================\n")

        var results: [ScenarioBenchmarkResult] = []

// 1. One idle companion
print("Running Scenario 1: One Idle Companion...")
let catDir = URL(fileURLWithPath: "Animatto/DefaultCompanions/Cat")
var petManager = PetManager()
PetManager.shared = petManager
var singlePet: PetInstance? = nil

let r1 = runScenario(
    name: "1. One Idle Companion",
    duration: 3.5,
    setup: {
        singlePet = PetInstance(url: catDir, size: 128, globalManager: petManager)
        singlePet?.currentState = .idle
        singlePet?.isFalling = false
        singlePet?.behaviorEngine.pauseAutonomousBehavior()
        petManager.activePets[singlePet!.id] = singlePet!
    },
    step: { dt in
        singlePet?.physicsTick(overrideDeltaTime: dt)
    },
    teardown: {
        singlePet?.closePet()
        petManager.activePets.removeAll()
        singlePet = nil
    }
)
results.append(r1)
print("  ✓ Done: CPU \(String(format: "%.2f%%", r1.avgCpuPercent)), RSS \(String(format: "%.1f MB", r1.residentRSSMB))")

// 2. Multiple active companions (5 active walking/exploring companions)
print("Running Scenario 2: Multiple Active Companions (5 companions)...")
var multiPets: [PetInstance] = []

let r2 = runScenario(
    name: "2. Multiple Active Companions (5)",
    duration: 3.5,
    setup: {
        for i in 1...5 {
            let p = PetInstance(url: catDir, size: 128, globalManager: petManager)
            p.currentState = .walk
            p.currentX = CGFloat(i * 120)
            p.currentY = 100
            p.isFalling = false
            multiPets.append(p)
            petManager.activePets[p.id] = p
        }
    },
    step: { dt in
        for p in multiPets {
            p.physicsTick(overrideDeltaTime: dt)
        }
    },
    teardown: {
        for p in multiPets { p.closePet() }
        multiPets.removeAll()
        petManager.activePets.removeAll()
    }
)
results.append(r2)
print("  ✓ Done: CPU \(String(format: "%.2f%%", r2.avgCpuPercent)), RSS \(String(format: "%.1f MB", r2.residentRSSMB))")

// 3. Aquarium Mode with multiple widgets (3 widgets transformed)
print("Running Scenario 3: Aquarium Mode (3 Transformed Widgets)...")
var aquariumPets: [PetInstance] = []
let aqManager = AquariumManager.shared

let r3 = runScenario(
    name: "3. Aquarium Mode (3 Widgets)",
    duration: 3.5,
    setup: {
        for i in 1...3 {
            let p = PetInstance(url: catDir, size: 128, globalManager: petManager)
            p.currentX = CGFloat(i * 180)
            p.currentY = 200
            aquariumPets.append(p)
            petManager.activePets[p.id] = p
        }
        aqManager.enableAquariumMode()
    },
    step: { dt in
        for p in aquariumPets {
            p.stepAquarium(dt: dt)
        }
    },
    teardown: {
        aqManager.disableAquariumMode()
        for p in aquariumPets { p.closePet() }
        aquariumPets.removeAll()
        petManager.activePets.removeAll()
    }
)
results.append(r3)
print("  ✓ Done: CPU \(String(format: "%.2f%%", r3.avgCpuPercent)), RSS \(String(format: "%.1f MB", r3.residentRSSMB))")

// 4. Ambient Worlds with high-quality effects
print("Running Scenario 4: Ambient Worlds High Quality (300 particles)...")
let ambientEngine = AmbientEngine.shared

let r4 = runScenario(
    name: "4. Ambient Worlds (High Quality)",
    duration: 3.5,
    setup: {
        ambientEngine.currentEnvironment = .rain
        ambientEngine.qualityMode = .highQuality
        ambientEngine.isEnabled = true
    },
    step: { dt in
        ambientEngine.tick()
    },
    teardown: {
        ambientEngine.isEnabled = false
        ambientEngine.qualityMode = .balanced
    }
)
results.append(r4)
print("  ✓ Done: CPU \(String(format: "%.2f%%", r4.avgCpuPercent)), RSS \(String(format: "%.1f MB", r4.residentRSSMB))")

// 5. Aquarium and Ambient Worlds running together
print("Running Scenario 5: Aquarium + Ambient Worlds Concurrently...")
var coexistingPets: [PetInstance] = []

let r5 = runScenario(
    name: "5. Aquarium + Ambient Worlds",
    duration: 3.5,
    setup: {
        for i in 1...3 {
            let p = PetInstance(url: catDir, size: 128, globalManager: petManager)
            p.currentX = CGFloat(i * 180)
            p.currentY = 200
            coexistingPets.append(p)
            petManager.activePets[p.id] = p
        }
        aqManager.enableAquariumMode()
        ambientEngine.currentEnvironment = .rain
        ambientEngine.qualityMode = .highQuality
        ambientEngine.isEnabled = true
    },
    step: { dt in
        for p in coexistingPets {
            p.stepAquarium(dt: dt)
        }
        ambientEngine.tick()
    },
    teardown: {
        aqManager.disableAquariumMode()
        ambientEngine.isEnabled = false
        for p in coexistingPets { p.closePet() }
        coexistingPets.removeAll()
        petManager.activePets.removeAll()
    }
)
results.append(r5)
print("  ✓ Done: CPU \(String(format: "%.2f%%", r5.avgCpuPercent)), RSS \(String(format: "%.1f MB", r5.residentRSSMB))")

// 6. Extended idle operation (10 seconds idle leak check)
print("Running Scenario 6: Extended Idle Operation (10s continuous)...")
var idlePet: PetInstance? = nil

let r6 = runScenario(
    name: "6. Extended Idle Operation (10s)",
    duration: 10.0,
    setup: {
        idlePet = PetInstance(url: catDir, size: 128, globalManager: petManager)
        idlePet?.currentState = .idle
        idlePet?.isFalling = false
        idlePet?.behaviorEngine.pauseAutonomousBehavior()
        petManager.activePets[idlePet!.id] = idlePet!
    },
    step: { dt in
        idlePet?.physicsTick(overrideDeltaTime: dt)
    },
    teardown: {
        idlePet?.closePet()
        petManager.activePets.removeAll()
        idlePet = nil
    }
)
results.append(r6)
print("  ✓ Done: CPU \(String(format: "%.2f%%", r6.avgCpuPercent)), RSS \(String(format: "%.1f MB", r6.residentRSSMB))")

// 7. Repeated mode switching (10 rapid transitions)
print("Running Scenario 7: Repeated Mode Switching (10 cycles)...")
var switchPet: PetInstance? = nil
var switchCount = 0

let r7 = runScenario(
    name: "7. Repeated Mode Switching (10x)",
    duration: 3.5,
    setup: {
        switchPet = PetInstance(url: catDir, size: 128, globalManager: petManager)
        petManager.activePets[switchPet!.id] = switchPet!
    },
    step: { dt in
        if switchCount < 10 {
            if switchCount % 2 == 0 {
                aqManager.enableAquariumMode()
            } else {
                aqManager.disableAquariumMode()
            }
            switchCount += 1
        }
        if switchPet?.isAquariumTransformed == true {
            switchPet?.stepAquarium(dt: dt)
        } else {
            switchPet?.physicsTick(overrideDeltaTime: dt)
        }
    },
    teardown: {
        aqManager.disableAquariumMode()
        switchPet?.closePet()
        petManager.activePets.removeAll()
        switchPet = nil
    }
)
results.append(r7)
print("  ✓ Done: CPU \(String(format: "%.2f%%", r7.avgCpuPercent)), RSS \(String(format: "%.1f MB", r7.residentRSSMB))\n")

// Print Final Report Table
print("\n================================================================================")
print(" FINAL EMPIRICAL MEASUREMENT RESULTS TABLE")
print("================================================================================")
print(String(format: "| %-32@ | %-10@ | %-10@ | %-12@ | %-10@ | %-10@ | %-14@ |",
             "Scenario", "Avg CPU", "Peak CPU", "Footprint", "RSS", "Tick Rate", "Wakeups/s"))
print("|----------------------------------|------------|------------|--------------|------------|------------|----------------|")

for r in results {
    print(String(format: "| %-32@ | %9.2f%% | %9.2f%% | %9.1f MB | %7.1f MB | %7.1f Hz | %12.1f/s |",
                 r.scenarioName,
                 r.avgCpuPercent,
                 r.peakCpuPercent,
                 r.physicalFootprintMB,
                 r.residentRSSMB,
                 r.measuredTickRate,
                 r.interruptWakeupsRate))
}
    print("================================================================================\n")
    }
}
