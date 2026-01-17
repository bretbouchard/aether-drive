import XCTest
@testable import SwiftFrontendCore

/// Comprehensive tests for deployment automation systems
final class DeploymentAutomationTests: XCTestCase {

    // MARK: - CanaryReleaseController Tests

    func testCanaryReleaseInitialization() async throws {
        let controller = CanaryReleaseController()
        XCTAssertNotNil(controller)
        XCTAssertEqual(controller.activeCanary, nil)
        XCTAssertEqual(controller.canaryHistory.count, 0)
    }

    func testCanaryReleaseStart() async throws {
        let controller = CanaryReleaseController()

        let config = CanaryConfig(
            version: "2.0.0",
            baselineVersion: "1.9.0",
            initialTrafficPercentage: 1,
            trafficSchedule: [
                TrafficStep(
                    percentage: 5,
                    duration: 300,
                    waitTime: 60,
                    description: "Initial canary"
                ),
                TrafficStep(
                    percentage: 25,
                    duration: 600,
                    waitTime: 120,
                    description: "Expanded canary"
                ),
                TrafficStep(
                    percentage: 100,
                    duration: 300,
                    waitTime: 60,
                    description: "Full rollout"
                )
            ],
            successCriteria: SuccessCriteria(
                errorRateThreshold: 0.01,
                latencyThreshold: 0.5,
                cpuThreshold: 80.0,
                memoryThreshold: 1024.0
            ),
            rollbackThresholds: RollbackThresholds(
                errorRate: 0.05,
                latency: 1.0,
                crashRate: 0.01,
                userComplaints: 10,
                timeToRollback: 60
            )
        )

        let canary = try await controller.startCanary(config)

        XCTAssertNotNil(canary)
        XCTAssertEqual(canary.version, "2.0.0")
        XCTAssertEqual(canary.baselineVersion, "1.9.0")
        XCTAssertEqual(canary.currentTrafficPercentage, 1)
        XCTAssertEqual(canary.status, .running)
    }

    func testCanaryReleaseTrafficAdjustment() async throws {
        let controller = CanaryReleaseController()

        let config = CanaryConfig(
            version: "2.0.0",
            baselineVersion: "1.9.0",
            initialTrafficPercentage: 1,
            trafficSchedule: [],
            successCriteria: SuccessCriteria(
                errorRateThreshold: 0.01,
                latencyThreshold: 0.5,
                cpuThreshold: 80.0,
                memoryThreshold: 1024.0
            ),
            rollbackThresholds: RollbackThresholds(
                errorRate: 0.05,
                latency: 1.0,
                crashRate: 0.01,
                userComplaints: 10,
                timeToRollback: 60
            )
        )

        let canary = try await controller.startCanary(config)

        // Test traffic adjustment
        try await controller.adjustTraffic(canary, percentage: 25)

        XCTAssertEqual(controller.activeCanary?.currentTrafficPercentage, 25)
    }

    func testCanaryReleasePromotion() async throws {
        let controller = CanaryReleaseController()

        let config = CanaryConfig(
            version: "2.0.0",
            baselineVersion: "1.9.0",
            initialTrafficPercentage: 1,
            trafficSchedule: [],
            successCriteria: SuccessCriteria(
                errorRateThreshold: 0.01,
                latencyThreshold: 0.5,
                cpuThreshold: 80.0,
                memoryThreshold: 1024.0
            ),
            rollbackThresholds: RollbackThresholds(
                errorRate: 0.05,
                latency: 1.0,
                crashRate: 0.01,
                userComplaints: 10,
                timeToRollback: 60
            )
        )

        let canary = try await controller.startCanary(config)

        // Test promotion
        try await controller.promoteCanary(canary)

        XCTAssertEqual(controller.activeCanary?.currentTrafficPercentage, 100)
        XCTAssertEqual(controller.activeCanary?.status, .successful)
    }

    func testCanaryReleaseRollback() async throws {
        let controller = CanaryReleaseController()

        let config = CanaryConfig(
            version: "2.0.0",
            baselineVersion: "1.9.0",
            initialTrafficPercentage: 1,
            trafficSchedule: [],
            successCriteria: SuccessCriteria(
                errorRateThreshold: 0.01,
                latencyThreshold: 0.5,
                cpuThreshold: 80.0,
                memoryThreshold: 1024.0
            ),
            rollbackThresholds: RollbackThresholds(
                errorRate: 0.05,
                latency: 1.0,
                crashRate: 0.01,
                userComplaints: 10,
                timeToRollback: 60
            )
        )

        let canary = try await controller.startCanary(config)

        // Test rollback
        try await controller.rollbackCanary(canary)

        XCTAssertEqual(controller.activeCanary, nil)
        XCTAssertEqual(controller.canaryHistory.last?.status, .rolledBack)
    }

    // MARK: - BlueGreenDeployment Tests

    func testBlueGreenDeploymentInitialization() async throws {
        let deployment = BlueGreenDeployment()
        XCTAssertNotNil(deployment)
        XCTAssertEqual(deployment.activeDeployment, nil)
    }

    func testBlueGreenDeploy() async throws {
        let deployment = BlueGreenDeployment()

        let result = try await deployment.deploy("2.0.0", to: .production)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.version, "2.0.0")
        XCTAssertEqual(result.environment, .production)
        XCTAssertEqual(result.status, .active)
    }

    func testBlueGreenTrafficSwitch() async throws {
        let deployment = BlueGreenDeployment()

        let bgDeployment = try await deployment.deploy("2.0.0", to: .production)

        // Test traffic switch
        try await deployment.switchTraffic(bgDeployment, to: .green)

        XCTAssertEqual(deployment.activeDeployment?.activeColor, .green)
    }

    func testBlueGreenValidation() async throws {
        let deployment = BlueGreenDeployment()

        let bgDeployment = try await deployment.deploy("2.0.0", to: .production)

        // Test validation
        let results = try await deployment.validateDeployment(bgDeployment)

        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.passed })
    }

    func testBlueGreenRollback() async throws {
        let deployment = BlueGreenDeployment()

        let bgDeployment = try await deployment.deploy("2.0.0", to: .production)

        // Test rollback
        try await deployment.rollback(bgDeployment)

        XCTAssertEqual(deployment.activeDeployment?.status, .rollingBack)
    }

    // MARK: - AutomatedRollback Tests

    func testAutomatedRollbackInitialization() async throws {
        let rollback = AutomatedRollback()
        XCTAssertNotNil(rollback)
        XCTAssertEqual(rollback.rollbackHistory.count, 0)
    }

    func testAutomatedRollbackExecution() async throws {
        let rollback = AutomatedRollback()

        let deployment = Deployment(
            version: "2.0.0",
            environment: .production,
            deployedAt: Date().addingTimeInterval(-3600),
            deploymentType: .blueGreen
        )

        let result = try await rollback.executeRollback(deployment)

        XCTAssertNotNil(result)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.previousVersion, "2.0.0")
    }

    func testAutomatedRollbackValidation() async throws {
        let rollback = AutomatedRollback()

        let deployment = Deployment(
            version: "2.0.0",
            environment: .production,
            deployedAt: Date().addingTimeInterval(-3600),
            deploymentType: .blueGreen
        )

        let result = try await rollback.executeRollback(deployment)

        // Test validation
        try await rollback.validateRollback(result)

        XCTAssertTrue(result.validationPassed)
    }

    func testAutomatedRollbackReportGeneration() async throws {
        let rollback = AutomatedRollback()

        let deployment = Deployment(
            version: "2.0.0",
            environment: .production,
            deployedAt: Date().addingTimeInterval(-3600),
            deploymentType: .blueGreen
        )

        let result = try await rollback.executeRollback(deployment)

        // Create a mock rollback record for report generation
        let record = RollbackRecord(
            deployment: DeploymentInfo(
                version: "2.0.0",
                environment: .production,
                deployedAt: Date().addingTimeInterval(-3600),
                deploymentType: .blueGreen
            ),
            rollbackVersion: "1.9.0",
            trigger: RollbackTrigger(
                name: "High Error Rate",
                type: .errorRate,
                condition: .threshold(0.05),
                severity: .immediate,
                enabled: true
            ),
            reason: "Automated rollback triggered",
            startedAt: Date().addingTimeInterval(-120),
            completedAt: Date(),
            duration: 120,
            successful: true,
            postRollbackValidation: ValidationResult(
                type: .userAcceptance,
                passed: true,
                message: "Rollback validation successful",
                details: [],
                timestamp: Date()
            ),
            userImpact: UserImpact(
                affectedUsers: 100,
                downtimeSeconds: 120,
                errorCount: 25,
                complaints: 0,
                impact: .medium
            )
        )

        let report = try rollback.generateRollbackReport(record)

        XCTAssertNotNil(report)
        XCTAssertEqual(report.rollback.rollbackVersion, "1.9.0")
        XCTAssertFalse(report.timeline.isEmpty)
        XCTAssertFalse(report.recommendations.isEmpty)
        XCTAssertFalse(report.preventiveActions.isEmpty)
    }

    // MARK: - FeatureFlagManager Tests

    func testFeatureFlagManagerInitialization() async throws {
        let manager = FeatureFlagManager()
        XCTAssertNotNil(manager)
        XCTAssertEqual(manager.flags.count, 0)
    }

    func testFeatureFlagCreation() async throws {
        let manager = FeatureFlagManager()

        let flag = FeatureFlag(
            name: "test_feature",
            description: "Test feature flag",
            type: .boolean,
            enabled: true,
            value: .boolean(true),
            rolloutStrategy: RolloutStrategy(
                type: .allOrNothing,
                percentage: 100,
                rules: [],
                schedule: nil
            ),
            targetingRules: [],
            dependencies: [],
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: "test",
            tags: ["test"]
        )

        try await manager.createFlag(flag)

        XCTAssertEqual(manager.flags.count, 1)
        XCTAssertEqual(manager.flags.first?.name, "test_feature")
    }

    func testFeatureFlagEnabledCheck() async throws {
        let manager = FeatureFlagManager()

        let flag = FeatureFlag(
            name: "test_feature",
            description: "Test feature flag",
            type: .boolean,
            enabled: true,
            value: .boolean(true),
            rolloutStrategy: RolloutStrategy(
                type: .allOrNothing,
                percentage: 100,
                rules: [],
                schedule: nil
            ),
            targetingRules: [],
            dependencies: [],
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: "test",
            tags: ["test"]
        )

        try await manager.createFlag(flag)

        let user = User(
            id: "test-user-123",
            email: "test@example.com",
            country: "US",
            deviceType: "iOS",
            appVersion: "2.0.0",
            attributes: [:],
            customAttributes: [:]
        )

        let isEnabled = manager.isEnabled("test_feature", for: user)

        XCTAssertTrue(isEnabled)
    }

    func testFeatureFlagRollout() async throws {
        let manager = FeatureFlagManager()

        let flag = FeatureFlag(
            name: "test_feature",
            description: "Test feature flag",
            type: .boolean,
            enabled: true,
            value: .boolean(true),
            rolloutStrategy: RolloutStrategy(
                type: .gradual,
                percentage: 0,
                rules: [],
                schedule: nil
            ),
            targetingRules: [],
            dependencies: [],
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: "test",
            tags: ["test"]
        )

        try await manager.createFlag(flag)

        // Test rollout
        try await manager.rollOutFlag("test_feature", percentage: 50)

        XCTAssertEqual(manager.flags.first?.rolloutStrategy.percentage, 50)
    }

    func testFeatureFlagDeletion() async throws {
        let manager = FeatureFlagManager()

        let flag = FeatureFlag(
            name: "test_feature",
            description: "Test feature flag",
            type: .boolean,
            enabled: true,
            value: .boolean(true),
            rolloutStrategy: RolloutStrategy(
                type: .allOrNothing,
                percentage: 100,
                rules: [],
                schedule: nil
            ),
            targetingRules: [],
            dependencies: [],
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: "test",
            tags: ["test"]
        )

        try await manager.createFlag(flag)

        let flagId = manager.flags.first?.id.uuidString ?? ""

        // Test deletion
        try await manager.deleteFlag(id: flagId)

        XCTAssertEqual(manager.flags.count, 0)
    }

    // MARK: - ProgressiveDelivery Tests

    func testProgressiveDeliveryInitialization() async throws {
        let delivery = ProgressiveDelivery()
        XCTAssertNotNil(delivery)
        XCTAssertEqual(delivery.activeDeliveries.count, 0)
    }

    func testProgressiveDeliveryStart() async throws {
        let delivery = ProgressiveDelivery()

        let config = DeliveryConfig(
            version: "2.0.0",
            stages: [
                DeliveryStage(
                    name: "Canary Deployment",
                    type: .canary,
                    order: 0,
                    config: .trafficPercentage(1),
                    successCriteria: SuccessCriteria(
                        errorRateThreshold: 0.01,
                        latencyThreshold: 0.5,
                        cpuThreshold: 80.0,
                        memoryThreshold: 1024.0
                    ),
                    rollbackStrategy: RollbackStrategy(
                        type: .allOrNothing,
                        percentage: 100,
                        rules: [],
                        schedule: nil
                    ),
                    duration: 300,
                    approvalRequired: false,
                    status: .pending
                ),
                DeliveryStage(
                    name: "Validation",
                    type: .validation,
                    order: 1,
                    config: .trafficPercentage(100),
                    successCriteria: SuccessCriteria(
                        errorRateThreshold: 0.01,
                        latencyThreshold: 0.5,
                        cpuThreshold: 80.0,
                        memoryThreshold: 1024.0
                    ),
                    rollbackStrategy: RollbackStrategy(
                        type: .allOrNothing,
                        percentage: 100,
                        rules: [],
                        schedule: nil
                    ),
                    duration: 300,
                    approvalRequired: false,
                    status: .pending
                )
            ],
            autoAdvance: false,
            approvalRequired: [],
            rollbackOnFailure: true,
            stakeholders: []
        )

        let pipeline = try await delivery.startDelivery(config)

        XCTAssertNotNil(pipeline)
        XCTAssertEqual(pipeline.version, "2.0.0")
        XCTAssertEqual(pipeline.stages.count, 2)
    }

    func testProgressiveDeliveryAdvance() async throws {
        let delivery = ProgressiveDelivery()

        let config = DeliveryConfig(
            version: "2.0.0",
            stages: [
                DeliveryStage(
                    name: "Canary Deployment",
                    type: .canary,
                    order: 0,
                    config: .trafficPercentage(1),
                    successCriteria: SuccessCriteria(
                        errorRateThreshold: 0.01,
                        latencyThreshold: 0.5,
                        cpuThreshold: 80.0,
                        memoryThreshold: 1024.0
                    ),
                    rollbackStrategy: RollbackStrategy(
                        type: .allOrNothing,
                        percentage: 100,
                        rules: [],
                        schedule: nil
                    ),
                    duration: 300,
                    approvalRequired: false,
                    status: .pending
                )
            ],
            autoAdvance: false,
            approvalRequired: [],
            rollbackOnFailure: true,
            stakeholders: []
        )

        let pipeline = try await delivery.startDelivery(config)

        // Test stage advancement
        try await delivery.advanceStage(pipeline)

        XCTAssertGreaterThan(delivery.activeDeliveries.first?.currentStage ?? 0, 0)
    }

    func testProgressiveDeliveryPause() async throws {
        let delivery = ProgressiveDelivery()

        let config = DeliveryConfig(
            version: "2.0.0",
            stages: [
                DeliveryStage(
                    name: "Canary Deployment",
                    type: .canary,
                    order: 0,
                    config: .trafficPercentage(1),
                    successCriteria: SuccessCriteria(
                        errorRateThreshold: 0.01,
                        latencyThreshold: 0.5,
                        cpuThreshold: 80.0,
                        memoryThreshold: 1024.0
                    ),
                    rollbackStrategy: RollbackStrategy(
                        type: .allOrNothing,
                        percentage: 100,
                        rules: [],
                        schedule: nil
                    ),
                    duration: 300,
                    approvalRequired: false,
                    status: .pending
                )
            ],
            autoAdvance: false,
            approvalRequired: [],
            rollbackOnFailure: true,
            stakeholders: []
        )

        let pipeline = try await delivery.startDelivery(config)

        // Test pause
        try await delivery.pauseDelivery(pipeline)

        XCTAssertEqual(delivery.activeDeliveries.first?.status, .paused)
    }

    func testProgressiveDeliveryRollback() async throws {
        let delivery = ProgressiveDelivery()

        let config = DeliveryConfig(
            version: "2.0.0",
            stages: [
                DeliveryStage(
                    name: "Canary Deployment",
                    type: .canary,
                    order: 0,
                    config: .trafficPercentage(1),
                    successCriteria: SuccessCriteria(
                        errorRateThreshold: 0.01,
                        latencyThreshold: 0.5,
                        cpuThreshold: 80.0,
                        memoryThreshold: 1024.0
                    ),
                    rollbackStrategy: RollbackStrategy(
                        type: .allOrNothing,
                        percentage: 100,
                        rules: [],
                        schedule: nil
                    ),
                    duration: 300,
                    approvalRequired: false,
                    status: .pending
                )
            ],
            autoAdvance: false,
            approvalRequired: [],
            rollbackOnFailure: true,
            stakeholders: []
        )

        let pipeline = try await delivery.startDelivery(config)

        // Test rollback
        try await delivery.rollbackDelivery(pipeline)

        XCTAssertEqual(delivery.deliveryHistory.first?.status, .rolledBack)
    }

    // MARK: - Integration Tests

    func testFullCanaryDeploymentWorkflow() async throws {
        // Test complete canary deployment workflow
        let canaryController = CanaryReleaseController()
        let rollback = AutomatedRollback()

        let config = CanaryConfig(
            version: "2.0.0",
            baselineVersion: "1.9.0",
            initialTrafficPercentage: 1,
            trafficSchedule: [
                TrafficStep(percentage: 5, duration: 60, waitTime: 30, description: "5%"),
                TrafficStep(percentage: 25, duration: 60, waitTime: 30, description: "25%"),
                TrafficStep(percentage: 100, duration: 60, waitTime: 30, description: "100%")
            ],
            successCriteria: SuccessCriteria(
                errorRateThreshold: 0.01,
                latencyThreshold: 0.5,
                cpuThreshold: 80.0,
                memoryThreshold: 1024.0
            ),
            rollbackThresholds: RollbackThresholds(
                errorRate: 0.05,
                latency: 1.0,
                crashRate: 0.01,
                userComplaints: 10,
                timeToRollback: 60
            )
        )

        // Start canary
        let canary = try await canaryController.startCanary(config)
        XCTAssertEqual(canary.status, .running)

        // Simulate successful metrics and promotion
        try await canaryController.promoteCanary(canary)
        XCTAssertEqual(canaryController.activeCanary?.status, .successful)
    }

    func testFullBlueGreenDeploymentWorkflow() async throws {
        // Test complete blue-green deployment workflow
        let bgDeployment = BlueGreenDeployment()

        // Deploy
        let deployment = try await bgDeployment.deploy("2.0.0", to: .production)
        XCTAssertEqual(deployment.status, .active)

        // Validate
        let results = try await bgDeployment.validateDeployment(deployment)
        XCTAssertTrue(results.allSatisfy { $0.passed })
    }

    func testFullProgressiveDeliveryWorkflow() async throws {
        // Test complete progressive delivery workflow
        let delivery = ProgressiveDelivery()

        let config = DeliveryConfig(
            version: "2.0.0",
            stages: [
                DeliveryStage(
                    name: "Canary",
                    type: .canary,
                    order: 0,
                    config: .trafficPercentage(1),
                    successCriteria: SuccessCriteria(
                        errorRateThreshold: 0.01,
                        latencyThreshold: 0.5,
                        cpuThreshold: 80.0,
                        memoryThreshold: 1024.0
                    ),
                    rollbackStrategy: RollbackStrategy(
                        type: .allOrNothing,
                        percentage: 100,
                        rules: [],
                        schedule: nil
                    ),
                    duration: 300,
                    approvalRequired: false,
                    status: .pending
                ),
                DeliveryStage(
                    name: "Validation",
                    type: .validation,
                    order: 1,
                    config: .trafficPercentage(100),
                    successCriteria: SuccessCriteria(
                        errorRateThreshold: 0.01,
                        latencyThreshold: 0.5,
                        cpuThreshold: 80.0,
                        memoryThreshold: 1024.0
                    ),
                    rollbackStrategy: RollbackStrategy(
                        type: .allOrNothing,
                        percentage: 100,
                        rules: [],
                        schedule: nil
                    ),
                    duration: 300,
                    approvalRequired: false,
                    status: .pending
                )
            ],
            autoAdvance: false,
            approvalRequired: [],
            rollbackOnFailure: true,
            stakeholders: []
        )

        let pipeline = try await delivery.startDelivery(config)
        XCTAssertNotNil(pipeline)
    }

    // MARK: - Performance Tests

    func testCanaryReleasePerformance() {
        let controller = CanaryReleaseController()

        measure {
            let config = CanaryConfig(
                version: "2.0.0",
                baselineVersion: "1.9.0",
                initialTrafficPercentage: 1,
                trafficSchedule: [],
                successCriteria: SuccessCriteria(
                    errorRateThreshold: 0.01,
                    latencyThreshold: 0.5,
                    cpuThreshold: 80.0,
                    memoryThreshold: 1024.0
                ),
                rollbackThresholds: RollbackThresholds(
                    errorRate: 0.05,
                    latency: 1.0,
                    crashRate: 0.01,
                    userComplaints: 10,
                    timeToRollback: 60
                )
            )

            // Measure canary creation performance
            Task {
                try? await controller.startCanary(config)
            }
        }
    }

    func testFeatureFlagEvaluationPerformance() {
        let manager = FeatureFlagManager()

        measure {
            // Test flag evaluation performance
            for _ in 0..<1000 {
                _ = manager.isEnabled("test_feature", for: nil)
            }
        }
    }
}
