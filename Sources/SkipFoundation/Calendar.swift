// Copyright 2023–2025 Skip
// SPDX-License-Identifier: LGPL-3.0-only WITH LGPL-3.0-linking-exception
#if SKIP

// Needed to expose `clone`:
// SKIP INSERT: fun java.util.Calendar.clone(): java.util.Calendar { return this.clone() as java.util.Calendar }

public struct Calendar : Hashable, Codable, CustomStringConvertible {
    internal var platformValue: java.util.Calendar

    public static var current: Calendar {
        return Calendar(platformValue: java.util.Calendar.getInstance())
    }

    @available(*, unavailable)
    public static var autoupdatingCurrent: Calendar {
        fatalError()
    }

    private static func platformValue(for identifier: Calendar.Identifier) -> java.util.Calendar {
        switch identifier {
        case .gregorian:
            return java.util.GregorianCalendar()
        case .iso8601:
            return java.util.Calendar.getInstance()
        default:
            // TODO: how to support the other calendars?
            return java.util.Calendar.getInstance()
        }
    }

    public init(_ platformValue: java.util.Calendar) {
        self.platformValue = platformValue
        self.locale = Locale.current
    }

    public init(identifier: Calendar.Identifier) {
        self.platformValue = Self.platformValue(for: identifier)
        self.locale = Locale.current
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let identifier = try container.decode(Calendar.Identifier.self)
        self.platformValue = Self.platformValue(for: identifier)
        self.locale = Locale.current
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(identifier)
    }

    public var locale: Locale

    public var timeZone: TimeZone {
        get {
            return TimeZone(platformValue.getTimeZone())
        }
        set {
            platformValue.setTimeZone(newValue.platformValue)
        }
    }

    public var description: String {
        return platformValue.description
    }

    public var identifier: Calendar.Identifier {
        // TODO: non-gregorian calendar
        if gregorianCalendar != nil {
            return Calendar.Identifier.gregorian
        } else {
            return Calendar.Identifier.iso8601
        }
    }

    internal func toDate() -> Date {
        Date(platformValue: platformValue.getTime())
    }

    private var dateFormatSymbols: java.text.DateFormatSymbols {
        java.text.DateFormatSymbols.getInstance(locale.platformValue)
    }

    private var gregorianCalendar: java.util.GregorianCalendar? {
        return platformValue as? java.util.GregorianCalendar
    }

    public var firstWeekday: Int {
        get {
            return platformValue.getFirstDayOfWeek()
        }
        set {
            platformValue.setFirstDayOfWeek(newValue)
        }
    }

    @available(*, unavailable)
    public var minimumDaysInFirstWeek: Int {
        fatalError()
    }

    public var eraSymbols: [String] {
        return Array(dateFormatSymbols.getEras().toList())
    }

    @available(*, unavailable)
    public var longEraSymbols: [String] {
        fatalError()
    }

    public var monthSymbols: [String] {
        // The java.text.DateFormatSymbols.getInstance().getMonths() method in Java returns an array of 13 symbols because it includes both the 12 months of the year and an additional symbol
        // some documentation says the blank symbol is at index 0, but other tests show it at the end, so just pare it out
        return Array(dateFormatSymbols.getMonths().toList()).filter({ $0?.isEmpty == false })
    }

    public var shortMonthSymbols: [String] {
        return Array(dateFormatSymbols.getShortMonths().toList()).filter({ $0?.isEmpty == false })
    }

    @available(*, unavailable)
    public var veryShortMonthSymbols: [String] {
        fatalError()
    }

    @available(*, unavailable)
    public var standaloneMonthSymbols: [String] {
        fatalError()
    }

    @available(*, unavailable)
    public var shortStandaloneMonthSymbols: [String] {
        fatalError()
    }

    @available(*, unavailable)
    public var veryShortStandaloneMonthSymbols: [String] {
        fatalError()
    }

    public var weekdaySymbols: [String] {
        return Array(dateFormatSymbols.getWeekdays().toList()).filter({ $0?.isEmpty == false })
    }

    public var shortWeekdaySymbols: [String] {
        return Array(dateFormatSymbols.getShortWeekdays().toList()).filter({ $0?.isEmpty == false })
    }

    @available(*, unavailable)
    public var veryShortWeekdaySymbols: [String] {
        fatalError()
    }

    @available(*, unavailable)
    public var standaloneWeekdaySymbols: [String] {
        fatalError()
    }

    @available(*, unavailable)
    public var shortStandaloneWeekdaySymbols: [String] {
        fatalError()
    }

    @available(*, unavailable)
    public var veryShortStandaloneWeekdaySymbols: [String] {
        fatalError()
    }

    @available(*, unavailable)
    public var quarterSymbols: [String] {
        fatalError()
    }

    @available(*, unavailable)
    public var shortQuarterSymbols: [String] {
        fatalError()
    }

    @available(*, unavailable)
    public var standaloneQuarterSymbols: [String] {
        fatalError()
    }

    @available(*, unavailable)
    public var shortStandaloneQuarterSymbols: [String] {
        fatalError()
    }

    public var amSymbol: String {
        return dateFormatSymbols.getAmPmStrings()[0]
    }

    public var pmSymbol: String {
        return dateFormatSymbols.getAmPmStrings()[1]
    }

    public func minimumRange(of component: Calendar.Component) -> Range<Int>? {
        let platformCal = platformValue.clone() as java.util.Calendar

        switch component {
        case .year:
            // Year typically starts at 1 and has no defined maximum.
            return 1..<platformCal.getMaximum(java.util.Calendar.YEAR)
        case .month:
            // Java's month is 0-based (0-11), but Swift expects 1-based (1-12).
            return 1..<(platformCal.getMaximum(java.util.Calendar.MONTH) + 2)
            
        case .day:
            // getMaximum() gives the largest value that field could theoretically have.
            // getActualMaximum() gives the largest value that field actually has for the specific calendar state.
            
            // calendar.getActualMaximum(java.util.Calendar.DATE)
            // will return 28 because February 2023 has 28 days (it’s not a leap year).
            platformCal.set(java.util.Calendar.DAY_OF_MONTH, 1)
            clearTime(in: platformCal)
            platformCal.set(java.util.Calendar.MONTH, java.util.Calendar.FEBRUARY)
            platformCal.set(java.util.Calendar.YEAR, 2023)
            // Minimum days in a month is 1, maximum can vary (28 for February).
            return platformCal.getMinimum(java.util.Calendar.DATE)..<platformCal.getActualMaximum(java.util.Calendar.DATE) + 1
        case .hour:
            // Hours are in the range 0-23.
            return platformCal.getMinimum(java.util.Calendar.HOUR_OF_DAY)..<(platformCal.getMaximum(java.util.Calendar.HOUR_OF_DAY) + 1)
            
        case .minute:
            // Minutes are in the range 0-59.
            return platformCal.getMinimum(java.util.Calendar.MINUTE)..<(platformCal.getMaximum(java.util.Calendar.MINUTE) + 1)
            
        case .second:
            // Seconds are in the range 0-59.
            return platformCal.getMinimum(java.util.Calendar.SECOND)..<(platformCal.getMaximum(java.util.Calendar.SECOND) + 1)
            
        case .weekday:
            // Weekday ranges from 1 (Sunday) to 7 (Saturday).
            return platformCal.getMinimum(java.util.Calendar.DAY_OF_WEEK)..<(platformCal.getMaximum(java.util.Calendar.DAY_OF_WEEK) + 1)
            
        case .weekOfMonth, .weekOfYear:
            // Not supported yet...
            fatalError()    
        case .quarter:
            // There are always 4 quarters in a year.
            return 1..<5
            
        default:
            return nil
        }
    }

    public func maximumRange(of component: Calendar.Component) -> Range<Int>? {
        let platformCal = platformValue.clone() as java.util.Calendar
        switch component {
        case .day:
            // Maximum number of days in a month can vary (e.g., 28, 29, 30, or 31 days)
            return platformCal.getMinimum(java.util.Calendar.DATE)..<(platformCal.getMaximum(java.util.Calendar.DATE) + 1)
        case .weekOfMonth, .weekOfYear:
            // Not supported yet...
            fatalError()
        default:
            // Maximum range is usually the same logic as minimum but could differ in some cases.
            return minimumRange(of: component)
        }
    }

    
    public func range(of smaller: Calendar.Component, in larger: Calendar.Component, for date: Date) -> Range<Int>? {
        let platformCal = platformValue.clone() as java.util.Calendar
        platformCal.time = date.platformValue
        
        switch larger {
        case .month:
            if smaller == .day {
                // Range of days in the current month
                let numDays = platformCal.getActualMaximum(java.util.Calendar.DAY_OF_MONTH)
                return 1..<(numDays + 1)
            } else if smaller == .weekOfMonth {
                // Range of weeks in the current month
                let numWeeks = platformCal.getActualMaximum(java.util.Calendar.WEEK_OF_MONTH)
                return 1..<(numWeeks + 1)
            }
        case .year:
            if smaller == .weekOfYear {
                // Range of weeks in the current year
                // Seems like Swift always returns Maximum not for an actual date
                let numWeeks = platformCal.getMaximum(java.util.Calendar.WEEK_OF_YEAR)
                return 1..<(numWeeks + 1)
            } else if smaller == .day {
                // Range of days in the current year
                let numDays = platformCal.getActualMaximum(java.util.Calendar.DAY_OF_YEAR)
                return 1..<(numDays + 1)
            } else if smaller == .month {
                // Range of months in the current year (1 to 12)
                return 1..<13
            }
        default:
            return nil
        }
        
        return nil
    }

    private func clearTime(in calendar: java.util.Calendar) {
        calendar.set(java.util.Calendar.HOUR_OF_DAY, 0) // “The HOUR_OF_DAY, HOUR and AM_PM fields are handled independently and the the resolution rule for the time of day is applied. Clearing one of the fields doesn't reset the hour of day value of this Calendar. Use set(Calendar.HOUR_OF_DAY, 0) to reset the hour value.”
        calendar.clear(java.util.Calendar.HOUR_OF_DAY)
        calendar.clear(java.util.Calendar.MINUTE)
        calendar.clear(java.util.Calendar.SECOND)
        calendar.clear(java.util.Calendar.MILLISECOND)
    }

    public func dateInterval(of component: Calendar.Component, start: inout Date, interval: inout TimeInterval, for date: Date) -> Bool {
        let platformCal = platformValue.clone() as java.util.Calendar
        platformCal.time = date.platformValue
        
        switch component {
        case .day:
            clearTime(in: platformCal)
            start = Date(platformValue: platformCal.time)
            interval = TimeInterval(24 * 60 * 60)
            return true
        case .month:
            platformCal.set(java.util.Calendar.DAY_OF_MONTH, 1)
            clearTime(in: platformCal)
            start = Date(platformValue: platformCal.time)
            let numberOfDays = platformCal.getActualMaximum(java.util.Calendar.DAY_OF_MONTH)
            interval = TimeInterval(numberOfDays) * TimeInterval(24 * 60 * 60)
            return true
        case .weekOfMonth, .weekOfYear:
            platformCal.set(java.util.Calendar.DAY_OF_WEEK, platformCal.firstDayOfWeek)
            clearTime(in: platformCal)
            start = Date(platformValue: platformCal.time)
            interval = TimeInterval(7 * 24 * 60 * 60)
            return true
        case .quarter:
            let currentMonth = platformCal.get(java.util.Calendar.MONTH)
            let quarterStartMonth = (currentMonth / 3) * 3  // Find the first month of the current quarter
            platformCal.set(java.util.Calendar.MONTH, quarterStartMonth)
            platformCal.set(java.util.Calendar.DAY_OF_MONTH, 1)
            clearTime(in: platformCal)
            start = Date(platformValue: platformCal.time)
            interval = TimeInterval(platformCal.getActualMaximum(java.util.Calendar.DAY_OF_MONTH)) * TimeInterval(24 * 60 * 60 * 3)
            return true
        default:
            return false
        }
    }

    public func dateInterval(of component: Calendar.Component, for date: Date) -> DateInterval? {
        var start = Date()
        var interval: TimeInterval = 0
        if dateInterval(of: component, start: &start, interval: &interval, for: date) {
            return DateInterval(start: start, duration: interval)
        }
        return nil
    }

    public func ordinality(of smaller: Calendar.Component, in larger: Calendar.Component, for date: Date) -> Int? {
        let platformCal = platformValue.clone() as java.util.Calendar
        platformCal.time = date.platformValue
        
        switch larger {
        case .year:
            if smaller == .day {
                return platformCal.get(java.util.Calendar.DAY_OF_YEAR)
            } else if smaller == .weekOfYear {
                return platformCal.get(java.util.Calendar.WEEK_OF_YEAR)
            }
        case .month:
            if smaller == .day {
                return platformCal.get(java.util.Calendar.DAY_OF_MONTH)
            } else if smaller == .weekOfMonth {
                return platformCal.get(java.util.Calendar.WEEK_OF_MONTH)
            }
        default:
            return nil
        }
        return nil
    }

    public func date(from components: DateComponents) -> Date? {
        var localComponents = components
        localComponents.calendar = self
        return Date(platformValue: localComponents.createCalendarComponents(timeZone: self.timeZone).getTime())
    }

    public func dateComponents(in zone: TimeZone? = nil, from date: Date) -> DateComponents {
        return DateComponents(fromCalendar: self, in: zone ?? self.timeZone, from: date)
    }

    public func dateComponents(_ components: Set<Calendar.Component>, from start: Date, to end: Date) -> DateComponents {
        return DateComponents(fromCalendar: self, in: self.timeZone, from: start, to: end)
    }

    public func dateComponents(_ components: Set<Calendar.Component>, from date: Date) -> DateComponents {
        return DateComponents(fromCalendar: self, in: self.timeZone, from: date, with: components)
    }

    public func date(byAdding components: DateComponents, to date: Date, wrappingComponents: Bool = false) -> Date? {
        var comps = DateComponents(fromCalendar: self, in: self.timeZone, from: date)
        if !wrappingComponents {
            comps.add(components)
        } else {
            comps.roll(components)
        }
        return date(from: comps)
    }

    public func date(byAdding component: Calendar.Component, value: Int, to date: Date, wrappingComponents: Bool = false) -> Date? {
        var comps = DateComponents(fromCalendar: self, in: self.timeZone, from: date)
        if !wrappingComponents {
            comps.addValue(value, for: component)
        } else {
            comps.rollValue(value, for: component)
        }
        return date(from: comps)
    }

    public func component(_ component: Calendar.Component, from date: Date) -> Int {
        return dateComponents([component], from: date).value(for: component) ?? 0
    }

    public func startOfDay(for date: Date) -> Date {
        // Clone the calendar to avoid mutating the original
        let platformCal = platformValue.clone() as java.util.Calendar
        platformCal.time = date.platformValue

        // Set the time components to the start of the day
        clearTime(in: platformCal)

        // Return the new Date representing the start of the day
        return Date(platformValue: platformCal.time)
    }

    public func compare(_ date1: Date, to date2: Date, toGranularity component: Calendar.Component) -> ComparisonResult {
        let platformCal1 = platformValue.clone() as java.util.Calendar
        let platformCal2 = platformValue.clone() as java.util.Calendar

        platformCal1.time = date1.platformValue
        platformCal2.time = date2.platformValue

        switch component {
        case .year:
            let year1 = platformCal1.get(java.util.Calendar.YEAR)
            let year2 = platformCal2.get(java.util.Calendar.YEAR)
            return year1 < year2 ? .ascending : year1 > year2 ? .descending : .same
        case .month:
            let year1 = platformCal1.get(java.util.Calendar.YEAR)
            let year2 = platformCal2.get(java.util.Calendar.YEAR)
            let month1 = platformCal1.get(java.util.Calendar.MONTH)
            let month2 = platformCal2.get(java.util.Calendar.MONTH)
            if year1 != year2 { return year1 < year2 ? .ascending : .descending }
            return month1 < month2 ? .ascending : month1 > month2 ? .descending : .same
        case .day:
            let year1 = platformCal1.get(java.util.Calendar.YEAR)
            let year2 = platformCal2.get(java.util.Calendar.YEAR)
            let day1 = platformCal1.get(java.util.Calendar.DAY_OF_YEAR)
            let day2 = platformCal2.get(java.util.Calendar.DAY_OF_YEAR)
            if year1 != year2 { return year1 < year2 ? .ascending : .descending }
            return day1 < day2 ? .ascending : day1 > day2 ? .descending : .same
        default:
            return .same
        }
    }

    public func isDate(_ date1: Date, equalTo date2: Date, toGranularity component: Calendar.Component) -> Bool {
        return compare(date1, to: date2, toGranularity: component) == .same
    }

    public func isDate(_ date1: Date, inSameDayAs date2: Date) -> Bool {
        return isDate(date1, equalTo: date2, toGranularity: .day)
    }

    public func isDateInToday(_ date: Date) -> Bool {
        let platformCal = platformValue.clone() as java.util.Calendar
        platformCal.time = Date().platformValue
        
        let targetCal = platformValue.clone() as java.util.Calendar
        targetCal.time = date.platformValue
        
        return platformCal.get(java.util.Calendar.YEAR) == targetCal.get(java.util.Calendar.YEAR)
            && platformCal.get(java.util.Calendar.DAY_OF_YEAR) == targetCal.get(java.util.Calendar.DAY_OF_YEAR)
    }

    @available(*, unavailable)
    public func isDateInYesterday(_ date: Date) -> Bool {
        fatalError()
    }

    @available(*, unavailable)
    public func isDateInTomorrow(_ date: Date) -> Bool {
        fatalError()
    }

    public func isDateInWeekend(_ date: Date) -> Bool {
        let components = dateComponents(from: date)
        return components.weekday == java.util.Calendar.SATURDAY || components.weekday == java.util.Calendar.SUNDAY
    }

    @available(*, unavailable)
    public func dateIntervalOfWeekend(containing date: Date, start: inout Date, interval: inout TimeInterval) -> Bool {
        fatalError()
    }

    @available(*, unavailable)
    public func dateIntervalOfWeekend(containing date: Date) -> DateInterval? {
        fatalError()
    }

    @available(*, unavailable)
    public func nextWeekend(startingAfter date: Date, start: inout Date, interval: inout TimeInterval, direction: Calendar.SearchDirection = .forward) -> Bool {
        fatalError()
    }

    @available(*, unavailable)
    public func nextWeekend(startingAfter date: Date, direction: Calendar.SearchDirection = .forward) -> DateInterval? {
        fatalError()
    }

    @available(*, unavailable)
    public func enumerateDates(startingAfter start: Date, matching components: DateComponents, matchingPolicy: Calendar.MatchingPolicy, repeatedTimePolicy: Calendar.RepeatedTimePolicy = .first, direction: Calendar.SearchDirection = .forward, using block: (_ result: Date?, _ exactMatch: Bool, _ stop: inout Bool) -> Void) {
        fatalError()
    }

    @available(*, unavailable)
    public func nextDate(after date: Date, matching components: DateComponents, matchingPolicy: Calendar.MatchingPolicy, repeatedTimePolicy: Calendar.RepeatedTimePolicy = .first, direction: Calendar.SearchDirection = .forward) -> Date? {
        fatalError()
    }

    @available(*, unavailable)
    public func date(bySetting component: Calendar.Component, value: Int, of date: Date) -> Date? {
        fatalError()
    }

    @available(*, unavailable)
    public func date(bySettingHour hour: Int, minute: Int, second: Int, of date: Date, matchingPolicy: Calendar.MatchingPolicy = .nextTime, repeatedTimePolicy: Calendar.RepeatedTimePolicy = .first, direction: Calendar.SearchDirection = .forward) -> Date? {
        fatalError()
    }

    @available(*, unavailable)
    public func date(_ date: Date, matchesComponents components: DateComponents) -> Bool {
        fatalError()
    }

    public enum Component: Sendable {
        case era
        case year
        case month
        case day
        case hour
        case minute
        case second
        case weekday
        case weekdayOrdinal
        case quarter
        case weekOfMonth
        case weekOfYear
        case yearForWeekOfYear
        case nanosecond
        case calendar
        case timeZone
    }

    /// Calendar supports many different kinds of calendars. Each is identified by an identifier here.
    public enum Identifier : Int, Codable, Sendable {
        /// The common calendar in Europe, the Western Hemisphere, and elsewhere.
        case gregorian
        case buddhist
        case chinese
        case coptic
        case ethiopicAmeteMihret
        case ethiopicAmeteAlem
        case hebrew
        case iso8601
        case indian
        case islamic
        case islamicCivil
        case japanese
        case persian
        case republicOfChina
        case islamicTabular
        case islamicUmmAlQura
    }

    public enum SearchDirection : Sendable {
        case forward
        case backward
    }

    public enum RepeatedTimePolicy : Sendable {
        case first
        case last
    }

    public enum MatchingPolicy : Sendable {
        case nextTime
        case nextTimePreservingSmallerComponents
        case previousTimePreservingSmallerComponents
        case strict
    }
}

extension Calendar: KotlinConverting<java.util.Calendar> {
    public override func kotlin(nocopy: Bool = false) -> java.util.Calendar {
        return nocopy ? platformValue : platformValue.clone() as java.util.Calendar
    }
}

#endif
