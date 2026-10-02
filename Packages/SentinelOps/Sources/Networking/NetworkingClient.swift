import Foundation

/// Transport implementations own URLSession delegate callbacks, pin validation,
/// and retry classification; higher layers receive only Sendable request results.
public protocol NetworkingClient: Sendable {}
