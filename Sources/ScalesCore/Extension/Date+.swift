
import Foundation

extension Date {
    
    static var oneMinuteAgo: Self {
        return Calendar.current.date(
          byAdding: .minute,
          value: -1,
          to: Date())!
    }
    
    static var oneHourAgo: Self {
        return Calendar.current.date(
          byAdding: .hour,
          value: -1,
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
