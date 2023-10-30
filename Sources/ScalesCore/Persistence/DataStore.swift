
import Foundation

public protocol DataStore {
    associatedtype SensorOutput
    func save(_ reading: SensorOutput) async throws
    func retrieve(count: Int) async throws -> [StoredReading<SensorOutput>]
}

public struct StoredReading<T> {
    let reading: T
    let date: Date
}
