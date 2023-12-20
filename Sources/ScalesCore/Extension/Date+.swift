
import Foundation

extension Date {
    
    static var oneMinuteAgo: Self {
        return Calendar.current.date(
          byAdding: .minute,
          value: -1,
          to: Date())!
    }
    
    static var tenMinutesAgo: Self {
        return Calendar.current.date(
          byAdding: .minute,
          value: -10,
          to: Date())!
    }
    
    static var oneHourAgo: Self {
        return Calendar.current.date(
          byAdding: .hour,
          value: -1,
          to: Date())!
    }
    
    static var sixHoursAgo: Self {
        return Calendar.current.date(
          byAdding: .hour,
          value: -6,
          to: Date())!
    }
    
    static var twelveHoursAgo: Self {
        return Calendar.current.date(
          byAdding: .hour,
          value: -12,
          to: Date())!
    }
    
    static var twentyFourHoursAgo: Self {
        return Calendar.current.date(
          byAdding: .hour,
          value: -24,
          to: Date())!
    }
    
    static var oneWeekAgo: Self {
        return Calendar.current.date(
            byAdding: .day,
          value: -7,
          to: Date())!
    }
    
    static var oneMonthAgo: Self {
        return Calendar.current.date(
          byAdding: .month,
          value: -1,
          to: Date())!
    }
    
    static var startOfThisYear: Self {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return DateComponents(calendar: calendar, year: currentYear).date!
    }
}

extension Date {
    var unixMillisSinceEpoch: Int {
        return Int(self.timeIntervalSince1970 * 1000)
    }
}

enum Since {
    
    case oneMinuteAgo
    case tenMinutesAgo
    case oneHourAgo
    case sixHoursAgo
    case twelveHoursAgo
    case twentyFourHoursAgo
    case oneWeekAgo
    case oneMonthAgo
    case startOfThisYear
    
    var date: Date {
        switch self {
            case .oneMinuteAgo:
                return .oneMinuteAgo
            case .tenMinutesAgo:
                return .tenMinutesAgo
            case .oneHourAgo:
                return .oneHourAgo
            case .sixHoursAgo:
                return .sixHoursAgo
            case .twelveHoursAgo:
                return .twelveHoursAgo
            case .twentyFourHoursAgo:
                return .twentyFourHoursAgo
            case .oneWeekAgo:
                return .oneWeekAgo
            case .oneMonthAgo:
                return .oneMonthAgo
            case .startOfThisYear:
                return .startOfThisYear
        }
    }
    
    var representativeMillis: Timestamped.UnixMillis {
        switch self {
            case .oneMinuteAgo:
                60000
            case .tenMinutesAgo:
                600000
            case .oneHourAgo:
                3600000
            case.sixHoursAgo:
                21600000
            case .twelveHoursAgo:
                43200000
            case .twentyFourHoursAgo:
                86400000
            case .oneWeekAgo:
                604800000
            case .oneMonthAgo:
                2629746000
            case .startOfThisYear:
                Date.startOfThisYear.unixMillisSinceEpoch
        }
    }
}
