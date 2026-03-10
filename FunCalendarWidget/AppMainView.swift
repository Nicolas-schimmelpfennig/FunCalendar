//  AppMainView.swift
//  FunCalendar
//
//  Created by Nicolas Schimmelpfennig on 09/02/2026.
//

import SwiftUI
import WidgetKit

struct AppMainView: View {
    // MARK: – Input
    let date: Date

    @State private var widgetMode: WidgetMode = .bar
    @State private var Deadline = Date()
    @State private var tempSelectedDate = Date()
    @State private var startDate = Date()
    @State private var tempStartDate = Date()
    @State private var todayColor: Color = .orange
    @State private var deadlineColor: Color = Color(red: 0.3, green: 1, blue: 1, opacity: 1)
    @State private var isDeadlineActive: Bool = true
    @State private var showProgressBar: Bool = true

    // MARK: – Widget Mode

    enum WidgetMode: String, CaseIterable, Identifiable {
        case bar = "Medium"
        case large = "Large"
       
        var id: String { rawValue }
    }

    let selectedDate = UserDefaults(suiteName: "group.com.nicolas.funCalendar")?
            .object(forKey: "selectedDate") as? Date

    // MARK: – Calendar Helpers
    private var widgetPreviewSize: CGSize {
        switch widgetMode {
        case .large:
            // iOS large widget (approx, system uses this internally)
            return CGSize(width: 360, height: 360)
        case .bar:
            // iOS medium widget (bar-style)
            return CGSize(width: 360, height: 169)
        }
    }

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

    private var daysRemaining: Int {
        guard isDeadlineActive else { return 0 }
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDeadline = calendar.startOfDay(for: Deadline)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfDeadline)
        return components.day ?? 0
    }

    private var totalDurationDays: Int {
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: Deadline)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(components.day ?? 0, 0)
    }

    private var daysRemainingText: String {
        guard isDeadlineActive else { return "" }
        if daysRemaining == 0 {
            return "Today's the day!"
        } else if daysRemaining == 1 {
            return "1 day to go"
        } else if daysRemaining < 0 {
            return "Deadline passed"
        } else {
            return "\(daysRemaining) days to go"
        }
    }

    private var progressValue: Double {
        guard isDeadlineActive else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: Deadline)

        if today <= start { return 0 }
        if today >= end { return 1 }

        let elapsed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return Double(elapsed) / Double(totalDurationDays)
    }

    // MARK: – Main Layout
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            

            // MODE SWITCHER
            Picker("Widget Type", selection: $widgetMode) {
                ForEach(WidgetMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            HStack {
                Spacer()
                widgetContainer {
                    widgetContent
                }
                Spacer()
            }
            
            Spacer(minLength: 24)
            // MARK: settings

            VStack(alignment: .leading, spacing: 8) {

                Text("Settings")
                    .font(.title.bold())
                    .padding(.horizontal)
                

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Deadline")
                            .font(.system(size: 20).bold())
                            .padding(.horizontal)
                      
                        // DEADLINE TOGGLE
                        Toggle("Deadline active", isOn: $isDeadlineActive)
                            .padding(.horizontal)
                            .onChange(of: isDeadlineActive) { _, _ in
                                saveToWidgetDefaults()
                            }
                        

                        // DATE SELECTION
                        if isDeadlineActive {
                            VStack(alignment: .leading, spacing: 12) {
                                
                                // DEADLINE DATE SELECTION
                                DatePicker(
                                    "Select deadline",
                                    selection: $tempSelectedDate,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .onChange(of: tempSelectedDate) { _, newValue in
                                    Deadline = max(newValue, startDate)
                                    saveToWidgetDefaults()
                                }
                                Toggle("Show Progress Bar", isOn: $showProgressBar)
                                    .onChange(of: showProgressBar) { _, _ in
                                        saveToWidgetDefaults()
                                    }
                            }
                            .padding(.horizontal)
                            if showProgressBar {
                                // START DATE SELECTION
                                
                                DatePicker(
                                    "Select start date",
                                    selection: $tempStartDate,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .onChange(of: tempStartDate) { _, newValue in
                                    startDate = min(newValue, Deadline)
                                    saveToWidgetDefaults()
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Divider()
                        // COLOR SELECTION
                        VStack(alignment: .leading, spacing: 12) {

                            Text("Colors")
                                .font(.system(size: 20).bold())

                            HStack {
                                Text("Today")
                                Spacer()
                                ColorPicker("", selection: $todayColor, supportsOpacity: true)
                                    .labelsHidden()
                                    .onChange(of: todayColor) { _, _ in
                                        saveToWidgetDefaults()
                                    }
                            }

                            if isDeadlineActive {
                                HStack {
                                    Text("Deadline")
                                    Spacer()
                                    ColorPicker("", selection: $deadlineColor, supportsOpacity: true)
                                        .labelsHidden()
                                        .onChange(of: deadlineColor) { _, _ in
                                            saveToWidgetDefaults()
                                        }
                                }
                            }

                            Button("Reset colors") {
                                todayColor = .orange
                                deadlineColor = Color(red: 0.3, green: 1, blue: 1, opacity: 1)
                            }
                            .buttonStyle(.borderedProminent)

                        }
                        .padding(.horizontal)
                    }
                    .padding(.init(top: 25, leading: 8, bottom: 25, trailing: 8))
                                        
                }
                .frame(maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(25)
                .padding()
            }
            
            
        }
        .padding(.top)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.black.opacity(0.1)))
        //.ignoresSafeArea()
        .onAppear {
            loadFromWidgetDefaults()
        }
        
       
    }

    // MARK: – Widget Preview Container
    @ViewBuilder
    private func widgetContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(
                width: widgetPreviewSize.width,
                height: widgetPreviewSize.height
            )
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.black.opacity(0.1)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )
    }

    // MARK: – Widget Preview Content
    private var widgetContent: some View {
        Group {
            if widgetMode == .large {
                largeWidgetLayout
            } else {
                barWidgetLayout
            }
        }
        .padding()
    }

    // MARK: – Large Widget Layout
    private var largeWidgetLayout: some View {
        VStack(alignment: .leading, spacing: 5) {

            HStack(alignment: .top, spacing: 5) {
                Text("\(day)")
                    .font(.system(size:85, weight: .bold))
                    //.background(Color(.red).opacity(0.1))


                VStack(alignment: .trailing) {
                    HStack {
                        Text("\(monthName.prefix(3))")
                            .font(.system(size: 25).bold())
                        Spacer()
                        Text("\(year.description)")
                            .font(.system(size:25, weight: .light))
                            
                    }
                    //.background(Color(.red).opacity(0.1))
                    Spacer()
                    if isDeadlineActive {
                        Text(daysRemainingText)
                            .font(.system(size:25, weight: .medium))
                            
                } else {
                        Text("No deadline set")
                        .font(.system(size:20, weight: .medium))
                        .opacity(0)
                    }
                }
                //.background(Color(.red).opacity(0.1))
                .padding(.vertical)
                
            }
            //.background(Color(.red).opacity(0.1))
           
            
            ProgressView(value: progressValue)
                .progressViewStyle(.linear)
                .tint(.primary)
                .frame(height: 4)
                .offset(y: -10)
                .opacity(isDeadlineActive && showProgressBar ? 1 : 0)
            
            MiniCalendarGridView(
                baseDate: date,
                startDate: startDate,
                deadline: Deadline,
                isDeadlineActive: isDeadlineActive,
                todayColor: todayColor,
                deadlineColor: deadlineColor,
                circleSize: 40,
                gridSpacing: 2)
            .padding(.bottom)

            Spacer(minLength: 0)
        }
        .padding()
        
    }

    // MARK: – Bar Widget Layout
    private var barWidgetLayout: some View {
        HStack(spacing: 12) {

            // LEFT SIDE
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 0) {

                    Text("\(day)")
                        .font(.system(size:75, weight: .bold))
                        .lineLimit(1)
                        .offset(x: 0, y: -15)
                        //.background(Color.red.opacity(0.15))
                        
              
                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(monthName.prefix(3))
                            .font(.system(size:18, weight: .semibold))

                        Text("\(year.description)")
                            .font(.system(size:16, weight: .light))
                        
                    }
                }
                //.background(Color.red.opacity(0.15))

                Spacer()
                
                if isDeadlineActive {
                    Text(daysRemainingText)
                        .font(.system(size:15, weight: .medium))
                    if showProgressBar {
                        ProgressView(value: progressValue)
                            .progressViewStyle(.linear)
                            .tint(.primary)
                            .frame(height: 4)
                    }
                }
            }

            Spacer()

            // RIGHT SIDE – MINI CALENDAR
            VStack(spacing: 6) {
                MiniCalendarGridView(
                    baseDate: date,
                    startDate: startDate,
                    deadline: Deadline,
                    isDeadlineActive: isDeadlineActive,
                    todayColor: todayColor,
                    deadlineColor: deadlineColor,
                    circleSize: 40,
                    gridSpacing: 2)
            }
            .scaleEffect(0.60)
            .frame(width: 132)
            .padding(.trailing, 20)
        }
        
    }

    
    
    
    // MARK: – Persistence (App Group)
private let appGroupID = "group.com.nicolas.funCalendar"

private func loadFromWidgetDefaults() {
    guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

    if let storedStart = defaults.object(forKey: "startDate") as? Date {
        startDate = storedStart
        tempStartDate = storedStart
    }

    if let storedDeadline = defaults.object(forKey: "deadline") as? Date {
        Deadline = storedDeadline
        tempSelectedDate = storedDeadline
    }

    isDeadlineActive = defaults.bool(forKey: "isDeadlineActive")
    showProgressBar = defaults.object(forKey: "showProgressBar") as? Bool ?? true

    if let data = defaults.data(forKey: "todayColor"),
       let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
        todayColor = Color(uiColor)
    }

    if let data = defaults.data(forKey: "deadlineColor"),
       let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
        deadlineColor = Color(uiColor)
    }
}

private func saveToWidgetDefaults() {
    guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

    defaults.set(date, forKey: "currentDate")
    defaults.set(startDate, forKey: "startDate")
    defaults.set(Deadline, forKey: "deadline")
    defaults.set(isDeadlineActive, forKey: "isDeadlineActive")
    defaults.set(showProgressBar, forKey: "showProgressBar")

    let todayUIColor = UIColor(todayColor)
    if let data = try? NSKeyedArchiver.archivedData(withRootObject: todayUIColor, requiringSecureCoding: false) {
        defaults.set(data, forKey: "todayColor")
    }

    let deadlineUIColor = UIColor(deadlineColor)
    if let data = try? NSKeyedArchiver.archivedData(withRootObject: deadlineUIColor, requiringSecureCoding: false) {
        defaults.set(data, forKey: "deadlineColor")
    }

    WidgetCenter.shared.reloadAllTimelines()
}

}

#Preview {
    AppMainView(
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 23))!
    )
}
