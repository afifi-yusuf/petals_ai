// Create a singleton HealthDataManager to encapsulate health data queries previously in DashboardView
// Move all health data async methods and summary logic here.
import Foundation
import HealthKit

@MainActor
class HealthDataManager {
    static let shared = HealthDataManager()
    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Data Status Structure
    struct HealthDataStatus {
        let value: Double
        let hasData: Bool
        let message: String
        let suggestion: String?
    }

    func requestHealthKitAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        #if DEBUG
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
        #else
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            if success {
                print("HealthKit authorization granted")
            }
        }
        #endif
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
        var summaryParts: [String] = []
        
        do {
            let steps = try await getSteps()
            if steps > 0 {
                summaryParts.append("Steps: \(Int(steps))")
            }
        } catch {
            // Don't add steps if there's an error
        }
        
        do {
            let heartRate = try await getHeartRate()
            if heartRate > 0 {
                summaryParts.append("Heart Rate: \(Int(heartRate)) BPM")
            }
        } catch {
            // Don't add heart rate if there's an error
        }
        
        do {
            let sleepHours = try await getSleepBreakdown()
            if sleepHours.total > 0 {
                summaryParts.append("Sleep: \(String(format: "%.1f", sleepHours.total))h")
            }
        } catch {
            // Don't add sleep if there's an error
        }
        
        do {
            let activeEnergy = try await getActiveEnergy()
            if activeEnergy > 0 {
                summaryParts.append("Energy: \(Int(activeEnergy)) kcal")
            }
        } catch {
            // Don't add energy if there's an error
        }
        
        do {
            let mindfulness = try await getMindfulnessMinutes()
            if mindfulness > 0 {
                summaryParts.append("Mindfulness: \(mindfulness) min")
            }
        } catch {
            // Don't add mindfulness if there's an error
        }
        
        // Add Screen Time to health summary

        
        // If no data is available, return a helpful message
        if summaryParts.isEmpty {
            return "No health data available today."
        }
        
        return summaryParts.joined(separator: " | ")
    }
    
    func getScreenTimeStatus() async -> HealthDataStatus {
            let suite = "group.com.petals.ai"                      // same group
            let key   = "screenTime.today.seconds"

            let seconds = (UserDefaults(suiteName: suite)?
                .integer(forKey: key)) ?? 0

            func format(_ s: Int) -> String {
                let h = s / 3600
                let m = (s % 3600) / 60
                if h > 0 { return "\(h)h \(m)m" }
                return "\(m)m"
            }

            if seconds > 0 {
                return HealthDataStatus(
                    value: Double(seconds),
                    hasData: true,
                    message: format(seconds),
                    suggestion: nil
                )
            } else {
                return HealthDataStatus(
                    value: 0,
                    hasData: false,
                    message: "No data",
                    suggestion: "Open Digital Wellness to refresh"
                )
            }
        }
    
    // MARK: - Enhanced Data Methods with Status
    func getStepsStatus() async -> HealthDataStatus {
        do {
            let steps = try await getSteps()
            if steps > 0 {
                return HealthDataStatus(
                    value: steps,
                    hasData: true,
                    message: "\(Int(steps))",
                    suggestion: nil
                )
            } else {
                return HealthDataStatus(
                    value: 0,
                    hasData: false,
                    message: "No data",
                    suggestion: "Try taking a walk or wearing your Apple Watch"
                )
            }
        } catch {
            return HealthDataStatus(
                value: 0,
                hasData: false,
                message: "No data",
                suggestion: "Check HealthKit permissions"
            )
        }
    }

    func getHeartRateStatus() async -> HealthDataStatus {
        do {
            let heartRate = try await getHeartRate()
            if heartRate > 0 {
                return HealthDataStatus(
                    value: heartRate,
                    hasData: true,
                    message: "\(Int(heartRate))",
                    suggestion: nil
                )
            } else {
                return HealthDataStatus(
                    value: 0,
                    hasData: false,
                    message: "No data",
                    suggestion: "Wear your Apple Watch to track heart rate"
                )
            }
        } catch {
            return HealthDataStatus(
                value: 0,
                hasData: false,
                message: "No data",
                suggestion: "Check HealthKit permissions"
            )
        }
    }

    func getMindfulnessStatus() async -> HealthDataStatus {
        do {
            let mindfulness = try await getMindfulnessMinutes()
            if mindfulness > 0 {
                return HealthDataStatus(
                    value: Double(mindfulness),
                    hasData: true,
                    message: "\(mindfulness) min",
                    suggestion: nil
                )
            } else {
                return HealthDataStatus(
                    value: 0,
                    hasData: false,
                    message: "No data",
                    suggestion: "Try a 5-minute meditation session"
                )
            }
        } catch {
            return HealthDataStatus(
                value: 0,
                hasData: false,
                message: "No data",
                suggestion: "Start with a guided meditation"
            )
        }
    }

    func getSleepStatus() async -> HealthDataStatus {
        do {
            let sleepHours = try await getSleepBreakdown()
            if sleepHours.total > 0 {
                return HealthDataStatus(
                    value: sleepHours.total,
                    hasData: true,
                    message: String(format: "%.1f h", sleepHours.total),
                    suggestion: nil
                )
            } else {
                return HealthDataStatus(
                    value: 0,
                    hasData: false,
                    message: "No data",
                    suggestion: "Wear your Apple Watch to bed"
                )
            }
        } catch {
            return HealthDataStatus(
                value: 0,
                hasData: false,
                message: "No data",
                suggestion: "Check HealthKit permissions"
            )
        }
    }

    func getActiveEnergyStatus() async -> HealthDataStatus {
        do {
            let activeEnergy = try await getActiveEnergy()
            if activeEnergy > 0 {
                return HealthDataStatus(
                    value: activeEnergy,
                    hasData: true,
                    message: "\(Int(activeEnergy))",
                    suggestion: nil
                )
            } else {
                return HealthDataStatus(
                    value: 0,
                    hasData: false,
                    message: "No data",
                    suggestion: "Try some light exercise"
                )
            }
        } catch {
            return HealthDataStatus(
                value: 0,
                hasData: false,
                message: "No data",
                suggestion: "Check HealthKit permissions"
            )
        }
    }

    // MARK: - Original Methods (kept for compatibility)
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
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicateForToday = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicateForToday,
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
