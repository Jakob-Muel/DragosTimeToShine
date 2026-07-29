import Foundation
import HealthKit

/// Standalone HealthKit provider used as the testable reference for the compiled
/// Objective-C++ Godot plugin in `native/ios/plugin`.
///
/// The Godot wrapper owns signal emission. Keeping HealthKit access in this small class makes
/// the native behavior testable without depending on the game UI.
final class StepHealthProvider {
    enum ProviderError: LocalizedError {
        case healthDataUnavailable
        case stepTypeUnavailable

        var errorDescription: String? {
            switch self {
            case .healthDataUnavailable:
                return "Health data is not available on this device."
            case .stepTypeUnavailable:
                return "The HealthKit step-count type is unavailable."
            }
        }
    }

    private let store = HKHealthStore()

    func requestPermission(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(ProviderError.healthDataUnavailable))
            return
        }
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(.failure(ProviderError.stepTypeUnavailable))
            return
        }

        store.requestAuthorization(toShare: [], read: [stepType]) { success, error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(success))
                }
            }
        }
    }

    func stepsSince(
        startUnix: TimeInterval,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(.failure(ProviderError.stepTypeUnavailable))
            return
        }

        let start = Date(timeIntervalSince1970: startUnix)
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictStartDate
        )
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, error in
            DispatchQueue.main.async {
                if let error {
                    completion(.failure(error))
                    return
                }
                let total = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                completion(.success(max(0, Int(total.rounded(.down)))))
            }
        }
        store.execute(query)
    }
}
