//  AppMainView.swift
//  FunCalendar
//
//  Created by Nicolas Schimmelpfennig on 09/02/2026.
//

import SwiftUI
import StoreKit
import Combine
import Foundation
import WidgetKit

struct AppMainView: View {
    // MARK: – Input
    let date: Date
    
    @StateObject private var store = StoreViewModel()

    @State private var widgetMode: WidgetMode = .bar
    @State private var Deadline = Date()
    @State private var tempSelectedDate = Date()
    @State private var startDate = Date()
    @State private var tempStartDate = Date()
    @State private var todayColor: Color = .orange
    @State private var deadlineColor: Color = Color(red: 0.3, green: 1, blue: 1, opacity: 1)
    @State private var lightBgColor: Color = Color(red: 0.8, green: 0.8, blue: 0.8)
    @State private var darkBgColor: Color = .black
    @State private var bgAppearanceMode: BgAppearanceMode = .dynamic
    @State private var isDeadlineActive: Bool = true
    @State private var showProgressBar: Bool = true
    @State private var showAbout: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    enum BgAppearanceMode: String, CaseIterable, Identifiable {
        case dynamic = "dynamic"
        case light = "light"
        case dark = "dark"
        var id: String { rawValue }
        var label: String {
            switch self {
            case .dynamic: return "Dynamic"
            case .light:   return "Light"
            case .dark:    return "Dark"
            }
        }
    }

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
            return "Nicely done!"
        } else {
            return "\(daysRemaining) days to go"
        }
    }

    private var daySuffix: String {
        switch day % 100 {
        case 11, 12, 13: return "th"
        default:
            switch day % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
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
        GeometryReader { geo in
            // iPhone is locked to portrait (Info.plist), so a landscape
            // aspect ratio can only occur on iPad.
            let isLandscape = geo.size.width > geo.size.height

            Group {
                if isLandscape {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.top)
        .background(Color(.black.opacity(0.1)))
        .sheet(isPresented: $showAbout) {
            AboutView(store: store)
                .presentationDetents([.large])
        }
        //.ignoresSafeArea()
        .onAppear {
            loadFromWidgetDefaults()
        }
    }

    // MARK: – Portrait Layout (iPhone + iPad portrait)
    private var portraitLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            modeSwitcher
            widgetPreview
            purchaseStatus
            settingsPane
            footer
        }
    }

    // MARK: – Landscape Layout (iPad only): preview left, settings right
    private var landscapeLayout: some View {
        HStack(alignment: .top, spacing: 0) {

            // LEFT – widget preview
            VStack(alignment: .leading, spacing: 8) {
                modeSwitcher
                widgetPreview
                purchaseStatus
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            // RIGHT – settings
            VStack(alignment: .leading, spacing: 8) {
                settingsPane
                footer
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: – Mode Switcher
    private var modeSwitcher: some View {
        Picker("Widget Type", selection: $widgetMode) {
            ForEach(WidgetMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: – Widget Preview
    private var widgetPreview: some View {
        HStack {
            Spacer()
            widgetContainer {
                widgetContent
            }
            Spacer()
        }
    }

    // MARK: – Purchase Status
    private var purchaseStatus: some View {
        VStack(alignment: .center) {

            if store.isPurchased {
                Label("Lifetime license active", systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
                    .font(.subheadline)

            } else {
                Label("Purchase a license to unlock widget customization.", systemImage: "newspaper")
                    .frame(maxWidth: .infinity)
                    .font(.subheadline)
                if let product = store.product {
                    HStack(spacing: 12) {
                        Button {
                            Task { await store.purchase() }
                        } label: {
                            Text("Buy \(product.displayPrice)")
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text("Restore")
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Text("Loading store...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: – Settings Pane
    private var settingsPane: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Settings")
                .font(.title.bold())
                .padding(.horizontal)


            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: Store status
                    HStack(spacing: 6) {
                        Image(systemName: store.storeError == nil ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(store.storeError == nil ? .green : .orange)
                        Text(store.storeError ?? "Store ready")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

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

                        Picker("Background mode", selection: $bgAppearanceMode) {
                            ForEach(BgAppearanceMode.allCases) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: bgAppearanceMode) { _, _ in saveToWidgetDefaults() }

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

                        HStack {
                            Text("Background (Light mode)")
                            Spacer()
                            ColorPicker("", selection: $lightBgColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: lightBgColor) { _, _ in
                                    saveToWidgetDefaults()
                                }
                        }

                        HStack {
                            Text("Background (Dark mode)")
                            Spacer()
                            ColorPicker("", selection: $darkBgColor, supportsOpacity: false)
                                .labelsHidden()
                                .onChange(of: darkBgColor) { _, _ in
                                    saveToWidgetDefaults()
                                }
                        }

                        Button("Reset colors") {
                            todayColor = .orange
                            deadlineColor = Color(red: 0.3, green: 1, blue: 1, opacity: 1)
                            lightBgColor = Color(red: 0.8, green: 0.8, blue: 0.8)
                            darkBgColor = .black
                            bgAppearanceMode = .dynamic
                            saveToWidgetDefaults()
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
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    // MARK: – Footer (About + version)
    private var footer: some View {
        HStack (alignment: .center, spacing: 10) {
            Spacer()
            Button("About") {
                showAbout = true
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                .font(.footnote)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }

    private var effectivePreviewBgColor: Color {
        switch bgAppearanceMode {
        case .dynamic: return colorScheme == .dark ? darkBgColor : lightBgColor
        case .light:   return lightBgColor
        case .dark:    return darkBgColor
        }
    }

    private var effectiveWidgetColorScheme: ColorScheme {
        switch bgAppearanceMode {
        case .dynamic: return colorScheme
        case .light:   return .light
        case .dark:    return .dark
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
                    .fill(effectivePreviewBgColor)
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
        .environment(\.colorScheme, effectiveWidgetColorScheme)
    }

    // MARK: – Large Widget Layout
    private var largeWidgetLayout: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .top, spacing: 5) {
                Text("\(day)")
                    .font(.system(size: 60, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .allowsTightening(true)
                    .offset(x: 0, y: -8)

                VStack(alignment: .trailing) {
                    HStack {
                        Text(daySuffix)
                            .font(.system(size: 20).bold())
                        Spacer()
                        Text("\(monthName.prefix(3))")
                            .font(.system(size: 20).bold())
                        Text("\(year.description)")
                            .font(.system(size: 20, weight: .light))
                    }
                    Text(daysRemainingText)
                        .font(.system(size: 20, weight: .medium))
                        .opacity(isDeadlineActive ? 1 : 0)
                        .allowsTightening(true)
                }
                .padding(.vertical, 2)
            }

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
                daySize: 10,
                circleSize: 37,
                gridSpacingX: 2,
                gridSpacingY: 2,
                headerSpacing: 5,
                headerLabelSpacing: 1)
        }
        .padding(.horizontal, 45)
    }

    // MARK: – Bar Widget Layout
    private var barWidgetLayout: some View {
        HStack(alignment: .top, spacing: 0) {

            // LEFT SIDE
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 0) {

                    Text("\(day)")
                        .font(.system(size: 70, weight: .bold))
                        .fixedSize()
                        .offset(x: 0, y: -13)


                    VStack(alignment: .trailing, spacing: 0) {
                        HStack {
                            Text(daySuffix)
                                .font(.system(size: 16).bold())
                            Spacer()
                            Text(monthName.prefix(3))
                                .font(.system(size: 16).bold())
                        }
                        
                        Text("\(year.description)")
                            .font(.system(size: 13, weight: .light))
                    }
                }

                Spacer()

                if isDeadlineActive {
                    Text(daysRemainingText)
                        .font(.system(size: 15, weight: .medium))
                    if showProgressBar {
                        ProgressView(value: progressValue)
                            .progressViewStyle(.linear)
                            .tint(.primary)
                            .frame(height: 4)
                    }
                }
            }
            .frame(width: 150, height: 135)
            .padding(.leading, 13)
            .padding(.top, 5)

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
                    daySize: 13,
                    circleSize: 40,
                    gridSpacingX: 2,
                    gridSpacingY: 2,
                    headerSpacing: 4,
                    headerLabelSpacing: 4)
            }
            .scaleEffect(0.55)
            .frame(width: 70, height: 150)
            .padding(.trailing, 60)
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

    if let data = defaults.data(forKey: "lightBgColor"),
       let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
        lightBgColor = Color(uiColor)
    }

    if let data = defaults.data(forKey: "darkBgColor"),
       let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
        darkBgColor = Color(uiColor)
    }

    if let raw = defaults.string(forKey: "bgAppearanceMode"),
       let mode = BgAppearanceMode(rawValue: raw) {
        bgAppearanceMode = mode
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

    let lightBgUIColor = UIColor(lightBgColor)
    if let data = try? NSKeyedArchiver.archivedData(withRootObject: lightBgUIColor, requiringSecureCoding: false) {
        defaults.set(data, forKey: "lightBgColor")
    }

    let darkBgUIColor = UIColor(darkBgColor)
    if let data = try? NSKeyedArchiver.archivedData(withRootObject: darkBgUIColor, requiringSecureCoding: false) {
        defaults.set(data, forKey: "darkBgColor")
    }

    defaults.set(bgAppearanceMode.rawValue, forKey: "bgAppearanceMode")

    WidgetCenter.shared.reloadAllTimelines()
}

}

@MainActor
final class StoreViewModel: ObservableObject {
    private let productIdentifier = "com.funcalendar.app.license"

    @Published var product: Product?
    @Published var isPurchased = false
    @Published var storeError: String?

    init() {
        listenForTransaction()
        Task {
            await loadProduct()
            await updatePurchaseStatus()
        }
    }

    func loadProduct() async {
        do {
            guard let loaded = try await Product.products(for: [productIdentifier]).first else {
                storeError = "Product not found. Check your StoreKit configuration or product ID."
                return
            }
            product = loaded
            storeError = nil
        } catch {
            storeError = "Failed to load product: \(error.localizedDescription)"
        }
    }

    func purchase() async {
        guard let product else {
            storeError = "Cannot purchase: product not loaded yet."
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchaseStatus()
                    storeError = nil
                case .unverified(_, let error):
                    storeError = "Purchase could not be verified: \(error.localizedDescription)"
                }
            case .userCancelled:
                break
            case .pending:
                storeError = "Purchase is pending approval (e.g. Ask to Buy)."
            @unknown default:
                storeError = "Unexpected purchase result."
            }
        } catch {
            storeError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func overridePurchase() {
        isPurchased = true
        UserDefaults(suiteName: "group.com.nicolas.funCalendar")?.set(true, forKey: "isPurchased")
        WidgetCenter.shared.reloadAllTimelines()
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
            if !isPurchased {
                storeError = "No previous purchase found for this Apple ID."
            } else {
                storeError = nil
            }
        } catch {
            storeError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func updatePurchaseStatus() async {
        if let result = await Transaction.latest(for: productIdentifier),
           case .verified(let transaction) = result {
            isPurchased = (transaction.revocationDate == nil)
        } else {
            isPurchased = false
        }
        UserDefaults(suiteName: "group.com.nicolas.funCalendar")?.set(isPurchased, forKey: "isPurchased")
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func listenForTransaction() {
        Task {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update,
                   transaction.productID == productIdentifier {
                    await transaction.finish()
                    await updatePurchaseStatus()
                }
            }
        }
    }
    
}

#Preview {
    AppMainView(
        date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 5))!
    )
}
