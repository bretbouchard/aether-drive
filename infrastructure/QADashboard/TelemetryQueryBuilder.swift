//
//  TelemetryQueryBuilder.swift
//  White Room QA Dashboard
//
//  Query builder for custom telemetry analytics
//

import Foundation

/// Telemetry query builder for custom analytics
public class TelemetryQueryBuilder {

    // MARK: - Query Building

    /// Build query from criteria
    public static func buildQuery(for criteria: QueryCriteria) -> TelemetryQuery {
        var query = TelemetryQuery()

        // Filter by date range
        if let startDate = criteria.startDate, let endDate = criteria.endDate {
            query.filters.append(.dateRange(start: startDate, end: endDate))
        }

        // Filter by event type
        if !criteria.eventTypes.isEmpty {
            query.filters.append(.eventTypes(criteria.eventTypes))
        }

        // Filter by screen
        if let screen = criteria.screen {
            query.filters.append(.screen(screen))
        }

        // Filter by user
        if let userId = criteria.userId {
            query.filters.append(.user(userId))
        }

        // Filter by session
        if let sessionId = criteria.sessionId {
            query.filters.append(.session(sessionId))
        }

        return query
    }

    /// Build query for UI interactions in date range
    public static func buildUIInteractionQuery(
        from startDate: Date,
        to endDate: Date,
        screen: String? = nil
    ) -> TelemetryQuery {
        var query = TelemetryQuery()
        query.filters.append(.dateRange(start: startDate, end: endDate))
        query.filters.append(.eventTypes([.uiInteraction]))

        if let screen = screen {
            query.filters.append(.screen(screen))
        }

        return query
    }

    /// Build query for performance issues
    public static func buildPerformanceQuery(
        from startDate: Date,
        to endDate: Date,
        minDuration: TimeInterval? = nil
    ) -> TelemetryQuery {
        var query = TelemetryQuery()
        query.filters.append(.dateRange(start: startDate, end: endDate))
        query.filters.append(.eventTypes([.performance]))

        if let minDuration = minDuration {
            query.filters.append(.custom("min_duration", minDuration))
        }

        return query
    }

    /// Build query for errors
    public static func buildErrorQuery(
        from startDate: Date,
        to endDate: Date,
        screen: String? = nil
    ) -> TelemetryQuery {
        var query = TelemetryQuery()
        query.filters.append(.dateRange(start: startDate, end: endDate))
        query.filters.append(.eventTypes([.error]))

        if let screen = screen {
            query.filters.append(.screen(screen))
        }

        return query
    }

    /// Build query for navigation flow
    public static func buildNavigationQuery(
        from startDate: Date,
        to endDate: Date,
        fromScreen: String? = nil,
        toScreen: String? = nil
    ) -> TelemetryQuery {
        var query = TelemetryQuery()
        query.filters.append(.dateRange(start: startDate, end: endDate))
        query.filters.append(.eventTypes([.navigation]))

        if let fromScreen = fromScreen {
            query.filters.append(.custom("from_screen", fromScreen))
        }

        if let toScreen = toScreen {
            query.filters.append(.custom("to_screen", toScreen))
        }

        return query
    }

    // MARK: - Query Execution

    /// Execute query against telemetry data store
    public static func executeQuery(_ query: TelemetryQuery) -> [TelemetryEvent] {
        // In production, this would query a persistent telemetry store
        // For now, return empty array
        // This would be integrated with UITelemetryTracker's event storage
        return []

        /*
         Production implementation:

         let tracker = UITelemetryTracker.shared
         let allEvents = tracker.getEvents()

         return allEvents.filter { event in
             return query.filters.allSatisfy { filter in
                 matchFilter(filter, event: event)
             }
         }
         */
    }

    /// Execute query and aggregate results
    public static func executeQueryWithAggregation(_ query: TelemetryQuery) -> TelemetryQueryResult {
        let events = executeQuery(query)

        let totalCount = events.count
        let byType = Dictionary(grouping: events, by: { $0.type })
            .mapValues { $0.count }
        let byScreen = Dictionary(grouping: events, by: { $0.screen })
            .mapValues { $0.count }

        return TelemetryQueryResult(
            query: query,
            events: events,
            totalCount: totalCount,
            countByType: byType,
            countByScreen: byScreen
        )
    }

    // MARK: - Private Methods

    private static func matchFilter(_ filter: QueryFilter, event: TelemetryEvent) -> Bool {
        switch filter {
        case .dateRange(let start, let end):
            return event.timestamp >= start && event.timestamp <= end

        case .eventTypes(let types):
            return types.contains(event.type)

        case .screen(let screen):
            return event.screen == screen

        case .user(let userId):
            return event.userId == userId

        case .session(let sessionId):
            return event.sessionId == sessionId

        case .custom(let key, let value):
            // Handle custom filters
            if key == "min_duration", let durationStr = event.context["duration"],
               let duration = Double(durationStr), let minValue = value as? TimeInterval {
                return duration >= minValue
            }

            if key == "from_screen", let fromScreen = event.context["destination"] {
                return fromScreen == value as? String
            }

            if key == "to_screen", let toScreen = event.context["destination"] {
                return toScreen == value as? String
            }

            return false
        }
    }
}

// MARK: - Telemetry Query

/// Telemetry query with filters
public struct TelemetryQuery: Codable {
    public var filters: [QueryFilter] = []

    /// Query description for logging
    public var description: String {
        guard !filters.isEmpty else { return "All Events" }

        let filterDescs = filters.map { filter in
            switch filter {
            case .dateRange(let start, let end):
                let formatter = ISO8601DateFormatter()
                return "Date: \(formatter.string(from: start)) to \(formatter.string(from: end))"
            case .eventTypes(let types):
                return "Types: \(types.map { $0.rawValue }.joined(separator: ", "))"
            case .screen(let screen):
                return "Screen: \(screen)"
            case .user(let userId):
                return "User: \(userId)"
            case .session(let sessionId):
                return "Session: \(sessionId)"
            case .custom(let key, let value):
                return "\(key): \(value)"
            }
        }

        return filterDescs.joined(separator: " AND ")
    }
}

// MARK: - Query Filter

/// Query filter for telemetry events
public enum QueryFilter: Codable {
    case dateRange(start: Date, end: Date)
    case eventTypes([TelemetryEventType])
    case screen(String)
    case user(String)
    case session(String)
    case custom(String, AnyCodable)

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case type
        case start
        case end
        case eventTypes
        case screen
        case user
        case session
        case customKey
        case customValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "dateRange":
            let start = try container.decode(Date.self, forKey: .start)
            let end = try container.decode(Date.self, forKey: .end)
            self = .dateRange(start: start, end: end)

        case "eventTypes":
            let types = try container.decode([TelemetryEventType].self, forKey: .eventTypes)
            self = .eventTypes(types)

        case "screen":
            let screen = try container.decode(String.self, forKey: .screen)
            self = .screen(screen)

        case "user":
            let user = try container.decode(String.self, forKey: .user)
            self = .user(user)

        case "session":
            let session = try container.decode(String.self, forKey: .session)
            self = .session(session)

        case "custom":
            let key = try container.decode(String.self, forKey: .customKey)
            let value = try container.decode(AnyCodable.self, forKey: .customValue)
            self = .custom(key, value)

        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type,
                in: container,
                debugDescription: "Invalid filter type"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .dateRange(let start, let end):
            try container.encode("dateRange", forKey: .type)
            try container.encode(start, forKey: .start)
            try container.encode(end, forKey: .end)

        case .eventTypes(let types):
            try container.encode("eventTypes", forKey: .type)
            try container.encode(types, forKey: .eventTypes)

        case .screen(let screen):
            try container.encode("screen", forKey: .type)
            try container.encode(screen, forKey: .screen)

        case .user(let user):
            try container.encode("user", forKey: .type)
            try container.encode(user, forKey: .user)

        case .session(let session):
            try container.encode("session", forKey: .type)
            try container.encode(session, forKey: .session)

        case .custom(let key, let value):
            try container.encode("custom", forKey: .type)
            try container.encode(key, forKey: .customKey)
            try container.encode(value, forKey: .customValue)
        }
    }
}

// MARK: - Any Codable

/// Type-erased codable value
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else {
            value = () // Empty
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Query Criteria

/// Criteria for building telemetry queries
public struct QueryCriteria {
    public let startDate: Date?
    public let endDate: Date?
    public let eventTypes: [TelemetryEventType]
    public let screen: String?
    public let userId: String?
    public let sessionId: String?

    public init(
        startDate: Date? = nil,
        endDate: Date? = nil,
        eventTypes: [TelemetryEventType] = [],
        screen: String? = nil,
        userId: String? = nil,
        sessionId: String? = nil
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.eventTypes = eventTypes
        self.screen = screen
        self.userId = userId
        self.sessionId = sessionId
    }

    /// Criteria for last N hours
    public static func lastHours(_ hours: Int) -> QueryCriteria {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: now)
        return QueryCriteria(startDate: startDate, endDate: now)
    }

    /// Criteria for last N days
    public static func lastDays(_ days: Int) -> QueryCriteria {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: now)
        return QueryCriteria(startDate: startDate, endDate: now)
    }

    /// Criteria for today
    public static var today: QueryCriteria {
        lastHours(24)
    }
}

// MARK: - Telemetry Query Result

/// Result of telemetry query with aggregations
public struct TelemetryQueryResult {
    public let query: TelemetryQuery
    public let events: [TelemetryEvent]
    public let totalCount: Int
    public let countByType: [TelemetryEventType: Int]
    public let countByScreen: [String: Int]

    /// Most common event types
    public var topEventTypes: [(TelemetryEventType, Int)] {
        countByType.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    /// Most common screens
    public var topScreens: [(String, Int)] {
        countByScreen.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }

    /// Average events per hour (for date range queries)
    public var averageEventsPerHour: Double? {
        guard let dateRangeFilter = query.filters.first(where: {
            if case .dateRange = $0 { return true }
            return false
        }), case .dateRange(let start, let end) = dateRangeFilter else {
            return nil
        }

        let hours = end.timeIntervalSince(start) / 3600
        guard hours > 0 else { return nil }

        return Double(totalCount) / hours
    }
}

// MARK: - Convenience Extensions

extension TelemetryQueryBuilder {
    /// Quick query for recent errors
    public static func recentErrors(hours: Int = 24) -> [TelemetryEvent] {
        let query = buildErrorQuery(
            from: Date().addingTimeInterval(-TimeInterval(hours * 3600)),
            to: Date()
        )
        return executeQuery(query)
    }

    /// Quick query for recent performance issues
    public static func recentPerformanceIssues(hours: Int = 24) -> [TelemetryEvent] {
        let query = buildPerformanceQuery(
            from: Date().addingTimeInterval(-TimeInterval(hours * 3600)),
            to: Date(),
            minDuration: 0.1 // >100ms
        )
        return executeQuery(query)
    }

    /// Quick query for screen activity
    public static func screenActivity(_ screen: String, hours: Int = 24) -> TelemetryQueryResult {
        let query = buildUIInteractionQuery(
            from: Date().addingTimeInterval(-TimeInterval(hours * 3600)),
            to: Date(),
            screen: screen
        )
        return executeQueryWithAggregation(query)
    }
}
