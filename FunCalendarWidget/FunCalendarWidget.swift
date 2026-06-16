//
//  FunCalendarWidget.swift
//  FunCalendarWidget
//
//  Created by Nicolas Schimmelpfennig on 04/12/2025.
//

import WidgetKit
import SwiftUI

private let appGroupID = "group.com.nicolas.funCalendar"

enum BgAppearanceMode: String {
    case dynamic = "dynamic"
    case light = "light"
    case dark = "dark"
}

struct WidgetAppState {
    let referenceDate: Date
    let startDate: Date?
    let deadline: Date?
    let isDeadlineActive: Bool
    let showProgressBar: Bool
    let todayColor: Color
    let deadlineColor: Color
    let lightBgColor: Color
    let darkBgColor: Color
    let bgAppearanceMode: BgAppearanceMode

    var daysRemaining: Int {
        guard isDeadlineActive,
              let deadline = deadline
        else { return 0 }

        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: referenceDate)
        let startOfDeadline = calendar.startOfDay(for: deadline)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfDeadline)
        return components.day ?? 0
    }

    var daysRemainingText: String {
        if daysRemaining == 0 {
            return "Today's the day!"
        } else if daysRemaining == 1 {
            return "1 day to go"
        } else if daysRemaining < 0 {
            return "Nicely done!"
        } else {
            return "\(daysRemaining) days to go"
        }
        
    }

    var progress: Double {
        guard isDeadlineActive,
              let startDate = startDate,
              let deadline = deadline
        else { return 0 }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: deadline)
        let today = calendar.startOfDay(for: referenceDate)

        guard end > start else { return 0 }

        let total = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        let elapsed = calendar.dateComponents([.day], from: start, to: today).day ?? 0

        if total <= 0 { return 0 }

        return min(max(Double(elapsed) / Double(total), 0), 1)
    }

    static func load(referenceDate: Date) -> WidgetAppState {
        let defaults = UserDefaults(suiteName: appGroupID)

        let startDate = defaults?.object(forKey: "startDate") as? Date
        let deadline = defaults?.object(forKey: "deadline") as? Date
        let isPurchased = defaults?.bool(forKey: "isPurchased") ?? false
        let isDeadlineActive = isPurchased && (defaults?.bool(forKey: "isDeadlineActive") ?? false)
        let showProgressBar = defaults?.bool(forKey: "showProgressBar") ?? false

        let todayColor: Color = {
            guard let data = defaults?.data(forKey: "todayColor"),
                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
            else { return .orange }
            return Color(uiColor)
        }()

        let deadlineColor: Color = {
            guard let data = defaults?.data(forKey: "deadlineColor"),
                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
            else { return .cyan }
            return Color(uiColor)
        }()

        let lightBgColor: Color = {
            guard isPurchased,
                  let data = defaults?.data(forKey: "lightBgColor"),
                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
            else { return Color(red: 0.8, green: 0.8, blue: 0.8) }
            return Color(uiColor)
        }()

        let darkBgColor: Color = {
            guard isPurchased,
                  let data = defaults?.data(forKey: "darkBgColor"),
                  let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
            else { return .black }
            return Color(uiColor)
        }()

        let bgAppearanceMode: BgAppearanceMode = {
            guard let raw = defaults?.string(forKey: "bgAppearanceMode") else { return .dynamic }
            return BgAppearanceMode(rawValue: raw) ?? .dynamic
        }()

        return WidgetAppState(
            referenceDate: referenceDate,
            startDate: startDate,
            deadline: deadline,
            isDeadlineActive: isDeadlineActive,
            showProgressBar: showProgressBar,
            todayColor: todayColor,
            deadlineColor: deadlineColor,
            lightBgColor: lightBgColor,
            darkBgColor: darkBgColor,
            bgAppearanceMode: bgAppearanceMode
        )
    }
}


// MARK: - Timeline Provider

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> DayEntry {
        DayEntry(date: Date(), configuration: configuration)
    }
    func getSelectedDate() -> Date {
        let defaults = UserDefaults(suiteName: "group.com.nicolas.funCalendar")
        return defaults?.object(forKey: "selectedDate") as? Date ?? Date()
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<DayEntry> {

        let calendar = Calendar.current
        let now = Date()

        // Create entries for the next 7 days to guarantee automatic daily updates
        var entries: [DayEntry] = []

        for offset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) {
                let entry = DayEntry(date: date, configuration: configuration)
                entries.append(entry)
            }
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - Entry

struct DayEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    var previewState: WidgetAppState? = nil
}


// MARK: - Widget Entry View

struct FunCalendarWidgetEntryView: View {
    var entry: DayEntry
    private var appState: WidgetAppState {
        entry.previewState ?? WidgetAppState.load(referenceDate: entry.date)
    }

    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme

    private var effectiveColorScheme: ColorScheme {
        switch appState.bgAppearanceMode {
        case .dynamic: return colorScheme
        case .light:   return .light
        case .dark:    return .dark
        }
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 6) {
                switch family {
                case .systemLarge:
                    MiniCalendarView(date: entry.date, appState: appState)

                case .systemMedium:
                    BarCalendarView(date: entry.date, appState: appState)

                case .systemSmall:
                    MiniCalendarView(date: entry.date, appState: appState)
                        .fixedSize()
                        .scaleEffect(0.45)

                default:
                    Text("Please choose the large, small or medium widget")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .environment(\.colorScheme, effectiveColorScheme)
        }
        .containerBackground(for: .widget) {
            switch appState.bgAppearanceMode {
            case .dynamic: colorScheme == .dark ? appState.darkBgColor : appState.lightBgColor
            case .light:   appState.lightBgColor
            case .dark:    appState.darkBgColor
            }
        }
    }
}


// MARK: - Widget

struct FunCalendarWidget: Widget {
    let kind = "FunCalendarWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            FunCalendarWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .supportedFamilies( [.systemSmall, .systemMedium, .systemLarge] )
    }
}


private extension Int {
    var ordinalSuffix: String {
        switch self % 100 {
        case 11, 12, 13: return "th"
        default:
            switch self % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }
}

// MARK: - Mini Calendar View

struct MiniCalendarView: View {
    let date: Date
    let appState: WidgetAppState
   
    
    // MARK: Calendar with Monday as first day
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }
   
    
    
    private var year: Int { calendar.component(.year, from: date) }
    private var month: Int { calendar.component(.month, from: date) }
    private var day: Int { calendar.component(.day, from: date) }
    private var monthName: String { calendar.monthSymbols[month - 1].uppercased() }
    
    private var weekdayString: String {
        calendar.shortWeekdaySymbols[(calendar.component(.weekday, from: date) + 5) % 7]
            .capitalized
    }

    
    
    // MARK: Month metadata
    private var monthStart: Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))!
    }
    
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: monthStart)!.count
    }
    
    private var firstWeekdayOffset: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    // MARK: 7x5 Calendar Grid (35 slots)
    private var gridDates: [Date] {
        let totalCells = 35
        
        // First visible date (may be in previous month)
        let firstVisibleDate = calendar.date(byAdding: .day, value: -firstWeekdayOffset, to: monthStart)!
        
        return (0..<totalCells).compactMap {
            calendar.date(byAdding: .day, value: $0, to: firstVisibleDate)
        }
    }
    // MARK: Large Calendar View
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .top, spacing: 5) {
                Text("\(day)")
                    .font(.system(size:60, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .allowsTightening(true)
                    .offset(x: 0, y: -8)
                  

                VStack(alignment: .trailing) {
                    HStack {
                        Text(day.ordinalSuffix)
                            .font(.system(size: 20).bold())
                        
                        Spacer()
                        
                        Text("\(monthName.prefix(3))")
                            .font(.system(size: 20).bold())
                        
                        Text("\(year.description)")
                            .font(.system(size:20, weight: .light))
                    }
                    Text(appState.daysRemainingText)
                        .font(.system(size: 20, weight: .medium))
                        .opacity(appState.isDeadlineActive ? 1 : 0)
                        .allowsTightening(true)
                }
                .padding(.vertical, 2)
            }

            ProgressView(value: appState.progress)
                .progressViewStyle(.linear)
                .tint(.primary)
                .frame(height: 4)
                .offset(y: -10)
                .opacity(appState.isDeadlineActive && appState.showProgressBar ? 1 : 0)

            MiniCalendarGridView(
                baseDate: date,
                startDate: appState.startDate ?? date,
                deadline: appState.deadline ?? date,
                isDeadlineActive: appState.isDeadlineActive,
                todayColor: appState.todayColor,
                deadlineColor: appState.deadlineColor,
                daySize: 10,
                circleSize: 37,
                gridSpacingX: 2,
                gridSpacingY: 2,
                headerSpacing: 5,
                headerLabelSpacing: 1)
        }
        .padding(.horizontal, 35)
       
    }
}





// MARK: - Bar (Medium) Calendar View

struct BarCalendarView: View {
    let date: Date
    let appState: WidgetAppState

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }

    private var day: Int { calendar.component(.day, from: date) }
    private var monthName: String { calendar.monthSymbols[calendar.component(.month, from: date) - 1].uppercased() }
    private var year: Int { calendar.component(.year, from: date) }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // LEFT SIDE
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top,spacing: 0) {

                    Text("\(day)")
                        .font(.system(size:70, weight: .bold))
                        .fixedSize()
                        .offset(x: 0, y: -13)
                        //.background(Color.red.opacity(0.15))
                        

                    VStack(alignment: .trailing, spacing: 0) {
                        HStack {
                            Text(day.ordinalSuffix)
                                .font(.system(size: 16).bold())
                            Spacer()
                            Text(monthName.prefix(3))
                                .font(.system(size: 16).bold())
                        }
                        
                        Text("\(year.description)")
                            .font(.system(size:13, weight: .light))
                            //.fixedSize()
                            
                        
                    }
                }
                //.background(Color.red.opacity(0.15))

                Spacer()

                if appState.isDeadlineActive {
                    Text(appState.daysRemainingText)
                        .font(.system(size:15, weight: .medium))
                    
                    if appState.showProgressBar {
                        ProgressView(value: appState.progress)
                            .progressViewStyle(.linear)
                            .tint(.primary)
                            .frame(height: 4)
                    }
                }
            }
            .frame(width: 150, height: 135)
            .padding(.leading, 13)
            .padding(.top, 5)
            //.background(Color.white)
            
            Spacer()

            // RIGHT SIDE – MINI CALENDAR
            VStack(spacing: 6) {

                MiniCalendarGridView(
                    baseDate: date,
                    startDate: appState.startDate ?? date,
                    deadline: appState.deadline ?? date,
                    isDeadlineActive: appState.isDeadlineActive,
                    todayColor: appState.todayColor,
                    deadlineColor: appState.deadlineColor,
                    daySize: 13,
                    circleSize: 40,
                    gridSpacingX: 2,
                gridSpacingY: 2,
                headerSpacing: 4,
                headerLabelSpacing: 4)
            }
            .scaleEffect(0.50)
            .frame(width: 70, height: 150)
            .padding(.trailing, 50)
            

        }
    }
}


// MARK: - Preview

#Preview("Today – Large", as: .systemLarge) {
    FunCalendarWidget()
} timeline: {
    DayEntry(
        date: Calendar.current.startOfDay(for: Date()),
        configuration: ConfigurationAppIntent()
    )
}

#Preview("custom date – Medium", as: .systemMedium) {
    FunCalendarWidget()
} timeline: {
    let previewDate = Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 10))!
    DayEntry(
        date: previewDate,
        configuration: ConfigurationAppIntent(),
        previewState: WidgetAppState(
            referenceDate: previewDate,
            startDate: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1))!,
            deadline: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 25))!,
            isDeadlineActive: true,
            showProgressBar: true,
            todayColor: .orange,
            deadlineColor: .cyan,
            lightBgColor: Color(red: 0.8, green: 0.8, blue: 0.8),
            darkBgColor: .black,
            bgAppearanceMode: .dynamic
        )
    )
}


