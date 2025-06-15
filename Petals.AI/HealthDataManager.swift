// Create a singleton HealthDataManager to encapsulate health data queries previously in DashboardView
// Move all health data async methods and summary logic here.
import Foundation
import HealthKit

@MainActor
class HealthDataManager {
    static let shared = HealthDataManager()
    private let healthStore = HKHealthStore()

    private init() {}

    func requestHealthKitAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                print("HealthKit authorization granted")
            }
        }
    }

    // Make this public so it can be called from the test button
    #if DEBUG
    public func populateSampleData() async {
        // Sample steps data
        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let stepsQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: 8432)
            let stepsSample = HKQuantitySample(
                type: stepType,
                quantity: stepsQuantity,
                start: Calendar.current.startOfDay(for: Date()),
                end: Date()
            )
            try? await healthStore.save(stepsSample)
        }

        // Sample heart rate data
        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            let heartRateQuantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: 72)
            let heartRateSample = HKQuantitySample(
                type: heartRateType,
                quantity: heartRateQuantity,
                start: Date().addingTimeInterval(-300), // 5 minutes ago
                end: Date()
            )
            try? await healthStore.save(heartRateSample)
        }

        // Sample sleep data
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            let sleepSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                start: Calendar.current.date(byAdding: .hour, value: -10, to: Date())!,
                end: Date()
            )
            try? await healthStore.save(sleepSample)
        }

        // Sample active energy data
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 450)
            let energySample = HKQuantitySample(
                type: energyType,
                quantity: energyQuantity,
                start: Calendar.current.startOfDay(for: Date()),
                end: Date()
            )
            try? await healthStore.save(energySample)
        }

        // Sample mindfulness data
        if let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            let mindfulnessSample = HKCategorySample(
                type: mindfulnessType,
                value: HKCategoryValue.notApplicable.rawValue,
                start: Date().addingTimeInterval(-1800), // 30 minutes ago
                end: Date()
            )
            try? await healthStore.save(mindfulnessSample)
        }
    }
    #else
    func populateSampleData() async {
        // This method is not available in release builds
        print("Sample data population is not available in release builds")
    }
    #endif

    func getHealthSummary() async -> String {
        var summary = "Health Summary:\n"
        do {
            let steps = try await getSteps()
            summary += "• Steps today: \(Int(steps))\n"
        } catch {
            summary += "• Steps: Error fetching data\n"
        }
        do {
            let heartRate = try await getHeartRate()
            summary += "• Current heart rate: \(Int(heartRate)) BPM\n"
        } catch {
            summary += "• Heart rate: Error fetching data\n"
        }
        do {
            let sleepHours = try await getSleepBreakdown()
            summary += "• Sleep last night: \(String(format: "%.1f", sleepHours.total)) hours\n"
            summary += "    ⤷ REM: \(String(format: "%.1f", sleepHours.rem))h, Deep: \(String(format: "%.1f", sleepHours.deep))h\n"
        } catch {
            summary += "• Sleep: Error fetching data\n"
        }
        do {
            let activeEnergy = try await getActiveEnergy()
            summary += "• Active energy burned: \(Int(activeEnergy)) kcal\n"
        } catch {
            summary += "• Active energy: Error fetching data\n"
        }
        do {
            let mindfulness = try await getMindfulnessMinutes()
            summary += "• Mindfulness practice: \(mindfulness) minutes\n"
        } catch {
            summary += "• Mindfulness: Error fetching data\n"
        }
        return summary
    }

    func getSteps() async throws -> Double {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsQuantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let stepCount = sum.doubleValue(for: HKUnit.count())
                continuation.resume(returning: stepCount)
            }
            self.healthStore.execute(query)
        }
    }

    func getHeartRate() async throws -> Double {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }
                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: heartRate)
            }
            self.healthStore.execute(query)
        }
    }

    private func getSleepBreakdown() async throws -> (total: Double, rem: Double, deep: Double) {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay.addingTimeInterval(-18 * 3600),
            end: endOfDay,
            options: .strictEndDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: (0.0, 0.0, 0.0))
                    return
                }

                var totalSleep: TimeInterval = 0
                var remSleep: TimeInterval = 0
                var deepSleep: TimeInterval = 0

                for sample in sleepSamples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                         HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        totalSleep += duration
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        totalSleep += duration
                        remSleep += duration
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        totalSleep += duration
                        deepSleep += duration
                    default:
                        break
                    }
                }

                continuation.resume(returning: (
                    total: totalSleep / 3600,
                    rem: remSleep / 3600,
                    deep: deepSleep / 3600
                ))
            }

            self.healthStore.execute(query)
        }
    }

    private func getActiveEnergy() async throws -> Double {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let activeEnergy = sum.doubleValue(for: HKUnit.kilocalorie())
                continuation.resume(returning: activeEnergy)
            }
            self.healthStore.execute(query)
        }
    }

    private func getMindfulnessMinutes() async throws -> Int {
        let mindfulnessType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulnessType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let mindfulnessSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                let totalMinutes = mindfulnessSamples.reduce(0) { total, sample in
                    total + Int(sample.endDate.timeIntervalSince(sample.startDate) / 60)
                }
                continuation.resume(returning: totalMinutes)
            }
            self.healthStore.execute(query)
        }
    }
}
