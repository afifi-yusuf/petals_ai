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
            // You can handle callback as needed
        }
    }

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
            let sleepHours = try await getSleepHours()
            summary += "• Sleep last night: \(String(format: "%.1f", sleepHours)) hours\n"
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

    private func getSleepHours() async throws -> Double {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let now = Date()
        let startOfDay = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
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
                    continuation.resume(returning: 0.0)
                    return
                }
                let totalSleepTime = sleepSamples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate)
                }
                let sleepHours = totalSleepTime / 3600
                continuation.resume(returning: sleepHours)
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
