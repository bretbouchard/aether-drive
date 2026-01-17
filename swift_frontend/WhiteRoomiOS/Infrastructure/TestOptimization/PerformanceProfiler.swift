//
//  PerformanceProfiler.swift
//  WhiteRoomiOS
//
//  Created by AI Assistant on 1/16/25.
//

import Foundation
import XCTest
import Darwin.Mach

/// Profiles test performance and identifies optimization opportunities
public class PerformanceProfiler: ObservableObject {

    // MARK: - Published Properties

    @Published public var profilingInProgress: Bool = false
    @Published public var profiles: [TestProfile] = []
    @Published public var lastProfilingDate: Date?

    // MARK: - Private Properties

    private let profileStore: TestProfileStore
    private let memoryProfiler: MemoryProfiler
    private let cpuProfiler: CPUProfiler

    // MARK: - Initialization

    public init(
        profileStore: TestProfileStore = .shared,
        memoryProfiler: MemoryProfiler = .shared,
        cpuProfiler: CPUProfiler = .shared
    ) {
        self.profileStore = profileStore
        self.memoryProfiler = memoryProfiler
        self.cpuProfiler = cpuProfiler
    }

    // MARK: - Public Methods

    /// Profiles a test by running it multiple times
    /// - Parameters:
    ///   - testName: Name of the test to profile
    ///   - iterations: Number of iterations to run (default: 10)
    /// - Returns: Test profile with performance metrics
    public func profileTest(
        _ testName: String,
        iterations: Int = 10
    ) -> TestProfile {
        profilingInProgress = true
        defer { profilingInProgress = false }

        var durations: [TimeInterval] = []
        var memoryUsages: [MemoryUsage] = []
        var cpuUsages: [Double] = []

        // Run test multiple times
        for _ in 0..<iterations {
            // Start profiling
            memoryProfiler.startProfiling()
            cpuProfiler.startProfiling()

            let startTime = Date()
            let result = runTestOnce(testName)
            let duration = Date().timeIntervalSince(startTime)

            // Stop profiling
            let memoryUsage = memoryProfiler.stopProfiling()
            let cpuUsage = cpuProfiler.stopProfiling()

            durations.append(duration)
            memoryUsages.append(memoryUsage)
            cpuUsages.append(cpuUsage)
        }

        // Calculate statistics
        let profile = calculateProfile(
            testName: testName,
            durations: durations,
            memoryUsages: memoryUsages,
            cpuUsages: cpuUsages
        )

        // Store profile
        profiles.append(profile)
        profileStore.saveProfile(profile)
        lastProfilingDate = Date()

        return profile
    }

    /// Identifies slow tests based on threshold
    /// - Parameter threshold: Duration threshold in seconds (default: 1.0)
    /// - Returns: Array of slow tests with optimization suggestions
    public func identifySlowTests(
        threshold: TimeInterval = 1.0
    ) -> [SlowTest] {
        return profiles
            .filter { $0.averageDuration > threshold }
            .map { profile in
                SlowTest(
                    testName: profile.testName,
                    duration: profile.averageDuration,
                    percentile: calculatePercentile(profile.averageDuration, among: profiles),
                    potentialOptimizations: generateOptimizations(for: profile),
                    impact: assessImpact(of: profile)
                )
            }
            .sorted { $0.duration > $1.duration }
    }

    /// Compares performance between baseline and current
    /// - Parameters:
    ///   - baseline: Baseline profile
    ///   - current: Current profile
    /// - Returns: Performance comparison
    public func comparePerformance(
        baseline: TestProfile,
        current: TestProfile
    ) -> PerformanceComparison {
        let timeChange = current.averageDuration - baseline.averageDuration
        let percentChange = baseline.averageDuration > 0 ?
            (timeChange / baseline.averageDuration) * 100 : 0

        let isRegression = percentChange > 10 // 10% threshold for regression
        let isImprovement = percentChange < -10 // 10% threshold for improvement

        return PerformanceComparison(
            baseline: baseline,
            current: current,
            timeChange: timeChange,
            percentChange: percentChange,
            isRegression: isRegression,
            isImprovement: isImprovement
        )
    }

    /// Generates a comprehensive performance report
    /// - Parameter profiles: Array of test profiles
    /// - Returns: Performance report
    public func generatePerformanceReport(_ profiles: [TestProfile]) -> PerformanceReport {
        let totalDuration = profiles.reduce(0.0) { $0 + $1.averageDuration }
        let averageDuration = profiles.isEmpty ? 0 : totalDuration / Double(profiles.count)
        let maxDuration = profiles.map { $0.averageDuration }.max() ?? 0
        let minDuration = profiles.map { $0.averageDuration }.min() ?? 0

        let slowTests = identifySlowTests()
        let memoryLeaks = detectMemoryLeaks(profiles)
        let performanceRegressions = detectRegressions(profiles)

        return PerformanceReport(
            generatedAt: Date(),
            totalTestCount: profiles.count,
            totalDuration: totalDuration,
            averageDuration: averageDuration,
            maxDuration: maxDuration,
            minDuration: minDuration,
            slowTests: slowTests,
            memoryLeaks: memoryLeaks,
            performanceRegressions: performanceRegressions,
            recommendations: generateRecommendations(
                slowTests: slowTests,
                memoryLeaks: memoryLeaks,
                regressions: performanceRegressions
            )
        )
    }

    /// Detects memory leaks in tests
    /// - Parameter profiles: Array of test profiles
    /// - Returns: Array of detected memory leaks
    public func detectMemoryLeaks(_ profiles: [TestProfile]) -> [MemoryLeak] {
        return profiles.compactMap { profile in
            // Check for increasing memory usage
            let memoryGrowth = profile.memoryUsage.endDelta - profile.memoryUsage.startDelta

            if memoryGrowth > 10_000_000 { // 10 MB threshold
                return MemoryLeak(
                    testName: profile.testName,
                    estimatedLeakSize: memoryGrowth,
                    confidence: calculateLeakConfidence(profile),
                    likelySources: identifyLeakSources(profile)
                )
            }
            return nil
        }
    }

    /// Gets performance trend over time
    /// - Parameter testName: Name of the test
    /// - Returns: Array of historical data points
    public func getPerformanceTrend(for testName: String) -> [PerformanceDataPoint] {
        let history = profileStore.getHistory(for: testName)
        return history.map { profile in
            PerformanceDataPoint(
                date: profile.timestamp,
                duration: profile.averageDuration,
                memoryUsage: profile.memoryUsage.usedMB,
                cpuUsage: profile.cpuUsage
            )
        }
    }

    /// Benchmarks test performance against target
    /// - Parameters:
    ///   - profile: Test profile
    ///   - targetDuration: Target duration
    /// - Returns: Benchmark result
    public func benchmarkAgainstTarget(
        _ profile: TestProfile,
        targetDuration: TimeInterval
    ) -> BenchmarkResult {
        let ratio = profile.averageDuration / targetDuration
        let status: BenchmarkStatus

        if ratio <= 1.0 {
            status = .withinTarget
        } else if ratio <= 1.2 {
            status = .slightlyOver
        } else if ratio <= 1.5 {
            status = .significantlyOver
        } else {
            status = .farExceeds
        }

        return BenchmarkResult(
            testName: profile.testName,
            actualDuration: profile.averageDuration,
            targetDuration: targetDuration,
            ratio: ratio,
            status: status
        )
    }

    // MARK: - Private Methods

    private func runTestOnce(_ testName: String) -> Bool {
        // This would integrate with XCTest to run a single test
        // For now, return a placeholder
        return true
    }

    private func calculateProfile(
        testName: String,
        durations: [TimeInterval],
        memoryUsages: [MemoryUsage],
        cpuUsages: [Double]
    ) -> TestProfile {
        let averageDuration = durations.reduce(0, +) / Double(durations.count)
        let minDuration = durations.min() ?? 0
        let maxDuration = durations.max() ?? 0

        // Calculate standard deviation
        let variance = durations.map { pow($0 - averageDuration, 2) }.reduce(0, +) / Double(durations.count)
        let stdDeviation = sqrt(variance)

        // Calculate percentiles
        let sortedDurations = durations.sorted()
        let percentiles: [Int: TimeInterval] = [
            50: sortedDurations[Int(sortedDurations.count * 50 / 100)],
            90: sortedDurations[Int(sortedDurations.count * 90 / 100)],
            95: sortedDurations[Int(sortedDurations.count * 95 / 100)],
            99: sortedDurations[Int(sortedDurations.count * 99 / 100)]
        ]

        // Average memory usage
        let averageMemory = MemoryUsage(
            usedMB: memoryUsages.map { $0.usedMB }.reduce(0, +) / Double(memoryUsages.count),
            peakMB: memoryUsages.map { $0.peakMB }.max() ?? 0,
            startDelta: memoryUsages.first?.startDelta ?? 0,
            endDelta: memoryUsages.last?.endDelta ?? 0
        )

        // Average CPU usage
        let averageCPU = cpuUsages.reduce(0, +) / Double(cpuUsages.count)

        return TestProfile(
            testName: testName,
            averageDuration: averageDuration,
            minDuration: minDuration,
            maxDuration: maxDuration,
            stdDeviation: stdDeviation,
            percentiles: percentiles,
            memoryUsage: averageMemory,
            cpuUsage: averageCPU,
            timestamp: Date()
        )
    }

    private func calculatePercentile(_ value: TimeInterval, among profiles: [TestProfile]) -> Double {
        let durations = profiles.map { $0.averageDuration }.sorted()
        guard let index = durations.firstIndex(of: value) else {
            return 50.0
        }
        return Double(index) / Double(durations.count) * 100
    }

    private func generateOptimizations(for profile: TestProfile) -> [String] {
        var optimizations: [String] = []

        // Check for high variance
        if profile.stdDeviation > profile.averageDuration * 0.3 {
            optimizations.append("High variance detected - stabilize test environment")
        }

        // Check for high memory usage
        if profile.memoryUsage.usedMB > 100 {
            optimizations.append("High memory usage - consider reducing test data size")
        }

        // Check for high CPU usage
        if profile.cpuUsage > 80 {
            optimizations.append("High CPU usage - optimize algorithms or add delays")
        }

        // Check for long duration
        if profile.averageDuration > 5.0 {
            optimizations.append("Test takes >5s - consider breaking into smaller tests")
        }

        // Check for memory leaks
        let memoryGrowth = profile.memoryUsage.endDelta - profile.memoryUsage.startDelta
        if memoryGrowth > 5_000_000 { // 5 MB
            optimizations.append("Possible memory leak detected - review object lifecycle")
        }

        return optimizations.isEmpty ? ["No obvious optimizations identified"] : optimizations
    }

    private func assessImpact(of profile: TestProfile) -> String {
        if profile.averageDuration > 10 {
            return "Critical - significantly slows down CI"
        } else if profile.averageDuration > 5 {
            return "High - delays feedback loop"
        } else if profile.averageDuration > 1 {
            return "Medium - accumulates with other slow tests"
        } else {
            return "Low - acceptable performance"
        }
    }

    private func detectRegressions(_ profiles: [TestProfile]) -> [PerformanceComparison] {
        var regressions: [PerformanceComparison] = []

        for profile in profiles {
            if let baseline = profileStore.getBaseline(for: profile.testName) {
                let comparison = comparePerformance(baseline: baseline, current: profile)
                if comparison.isRegression {
                    regressions.append(comparison)
                }
            }
        }

        return regressions
    }

    private func calculateLeakConfidence(_ profile: TestProfile) -> Double {
        let memoryGrowth = profile.memoryUsage.endDelta - profile.memoryUsage.startDelta
        let growthRate = memoryGrowth / profile.averageDuration

        if growthRate > 1_000_000 { // >1 MB/sec
            return 0.9 // High confidence
        } else if growthRate > 100_000 { // >100 KB/sec
            return 0.7 // Medium confidence
        } else {
            return 0.5 // Low confidence
        }
    }

    private func identifyLeakSources(_ profile: TestProfile) -> [String] {
        var sources: [String] = []

        // Analyze based on test name and characteristics
        if profile.testName.contains("Async") || profile.testName.contains("Wait") {
            sources.append("Possible retain cycle in async closures")
        }

        if profile.cpuUsage > 80 {
            sources.append("Possible leak in high-frequency operations")
        }

        if profile.memoryUsage.peakMB > profile.memoryUsage.usedMB * 2 {
            sources.append("Possible accumulation of temporary objects")
        }

        return sources.isEmpty ? ["Unable to determine specific source"] : sources
    }

    private func generateRecommendations(
        slowTests: [SlowTest],
        memoryLeaks: [MemoryLeak],
        regressions: [PerformanceComparison]
    ) -> [String] {
        var recommendations: [String] = []

        if !slowTests.isEmpty {
            recommendations.append("Optimize \(slowTests.count) slow tests to reduce CI time")
        }

        if !memoryLeaks.isEmpty {
            recommendations.append("Fix \(memoryLeaks.count) memory leaks to prevent long-term issues")
        }

        if !regressions.isEmpty {
            recommendations.append("Investigate \(regressions.count) performance regressions")
        }

        if slowTests.isEmpty && memoryLeaks.isEmpty && regressions.isEmpty {
            recommendations.append("All tests performing well - no immediate action needed")
        }

        return recommendations
    }
}

// MARK: - Supporting Types

public struct TestProfile: Identifiable, Codable {
    public let id = UUID()
    let testName: String
    let averageDuration: TimeInterval
    let minDuration: TimeInterval
    let maxDuration: TimeInterval
    let stdDeviation: TimeInterval
    let percentiles: [Int: TimeInterval]
    let memoryUsage: MemoryUsage
    let cpuUsage: Double
    let timestamp: Date
}

public struct SlowTest: Identifiable {
    public let id = UUID()
    let testName: String
    let duration: TimeInterval
    let percentile: Double
    let potentialOptimizations: [String]
    let impact: String
}

public struct PerformanceComparison: Identifiable {
    public let id = UUID()
    let baseline: TestProfile
    let current: TestProfile
    let timeChange: TimeInterval
    let percentChange: Double
    let isRegression: Bool
    let isImprovement: Bool
}

public struct PerformanceReport: Identifiable {
    public let id = UUID()
    let generatedAt: Date
    let totalTestCount: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let maxDuration: TimeInterval
    let minDuration: TimeInterval
    let slowTests: [SlowTest]
    let memoryLeaks: [MemoryLeak]
    let performanceRegressions: [PerformanceComparison]
    let recommendations: [String]
}

public struct MemoryUsage: Codable {
    let usedMB: Double
    let peakMB: Double
    let startDelta: Int64 // Bytes from start
    let endDelta: Int64 // Bytes at end
}

public struct MemoryLeak: Identifiable {
    public let id = UUID()
    let testName: String
    let estimatedLeakSize: Int64 // Bytes
    let confidence: Double // 0-1
    let likelySources: [String]
}

public struct PerformanceDataPoint: Identifiable {
    public let id = UUID()
    let date: Date
    let duration: TimeInterval
    let memoryUsage: Double
    let cpuUsage: Double
}

public struct BenchmarkResult: Identifiable {
    public let id = UUID()
    let testName: String
    let actualDuration: TimeInterval
    let targetDuration: TimeInterval
    let ratio: Double
    let status: BenchmarkStatus
}

public enum BenchmarkStatus {
    case withinTarget
    case slightlyOver
    case significantlyOver
    case farExceeds
}

// MARK: - Memory Profiler

public class MemoryProfiler {
    public static let shared = MemoryProfiler()

    private var startMemory: UInt64 = 0
    private var peakMemory: UInt64 = 0

    public func startProfiling() {
        startMemory = getCurrentMemoryUsage()
        peakMemory = startMemory
    }

    public func stopProfiling() -> MemoryUsage {
        let endMemory = getCurrentMemoryUsage()
        let usedMB = Double(endMemory - startMemory) / 1_048_576.0 // Convert to MB
        let peakMB = Double(peakMemory - startMemory) / 1_048_576.0

        return MemoryUsage(
            usedMB: usedMB,
            peakMB: peakMB,
            startDelta: Int64(startMemory),
            endDelta: Int64(endMemory)
        )
    }

    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
}

// MARK: - CPU Profiler

public class CPUProfiler {
    public static let shared = CPUProfiler()

    private var startTime: CFAbsoluteTime = 0
    private var startCPU: TimeInterval = 0

    public func startProfiling() {
        startTime = CFAbsoluteTimeGetCurrent()
        startCPU = getCPUUsage()
    }

    public func stopProfiling() -> Double {
        let endTime = CFAbsoluteTimeGetCurrent()
        let endCPU = getCPUUsage()

        let elapsed = endTime - startTime
        let cpuUsed = endCPU - startCPU

        return elapsed > 0 ? (cpuUsed / elapsed) * 100 : 0
    }

    private func getCPUUsage() -> TimeInterval {
        var totalUsageOfCPU: TimeInterval = 0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = withUnsafeMutablePointer(to: &threadsList) {
            return $0.withMemoryRebound(to: thread_act_array_t?.self, capacity: 1) {
                task_threads(mach_task_self_, $0, &threadsCount)
            }
        }

        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }

                if infoResult == KERN_SUCCESS {
                    let threadBasicInfo = threadInfo as thread_basic_info
                    if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                        totalUsageOfCPU += (Double(threadBasicInfo.user_time.seconds) + Double(threadBasicInfo.system_time.seconds))
                    }
                }
            }

            vm_deallocate(mach_task_self_, vm_address_t(UInt64(bitPattern: threadsList)), vm_size_t(Int(threadsCount)))
        }

        return totalUsageOfCPU
    }
}

// MARK: - Profile Store

public class TestProfileStore {
    public static let shared = TestProfileStore()

    private var profiles: [String: [TestProfile]] = [:]

    public func saveProfile(_ profile: TestProfile) {
        if profiles[profile.testName] == nil {
            profiles[profile.testName] = []
        }
        profiles[profile.testName]?.append(profile)
    }

    public func getHistory(for testName: String) -> [TestProfile] {
        return profiles[testName] ?? []
    }

    public func getBaseline(for testName: String) -> TestProfile? {
        return profiles[testName]?.first
    }

    public func clearHistory() {
        profiles.removeAll()
    }
}
