//
//  MiniCalendarGridView.swift
//  FunCalendar
//
//  Created by Nicolas Schimmelpfennig on 11/02/2026.
//

//
//  MiniCalendarGridView.swift
//  FunCalendar
//
//  Shared mini calendar grid used in both
//  App preview and Widget.
//

import SwiftUI

struct MiniCalendarGridView: View {
    
    // MARK: - Inputs
    
    let baseDate: Date               // The date being displayed (today in widget/app)
    let startDate: Date
    let deadline: Date
    let isDeadlineActive: Bool
    
    let todayColor: Color
    let deadlineColor: Color
    
    let daySize: CGFloat
    
    let circleSize: CGFloat          // 40 for large, 18 for bar, etc.
    let gridSpacing: CGFloat         // spacing between circles
    
    // MARK: - Calendar
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        return cal
    }
    
    private var year: Int {
        calendar.component(.year, from: baseDate)
    }
    
    private var month: Int {
        calendar.component(.month, from: baseDate)
    }
    
    private var monthStart: Date {
        calendar.date(from: DateComponents(year: year, month: month, day: 1))!
    }
    
    private var firstWeekdayOffset: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday - calendar.firstWeekday + 7) % 7
    }
    
    // MARK: - Grid Dates (7x5 = 35 cells)
    
    private var gridDates: [Date] {
        let totalCells = 42
        let firstVisibleDate = calendar.date(byAdding: .day,
                                             value: -firstWeekdayOffset,
                                             to: monthStart)!
        
        return (0..<totalCells).compactMap {
            calendar.date(byAdding: .day, value: $0, to: firstVisibleDate)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            let mondayFirst = Array(calendar.shortWeekdaySymbols[1...6]) + [calendar.shortWeekdaySymbols[0]]

            HStack(spacing: gridSpacing*2) {
                ForEach(mondayFirst, id: \.self) { symbol in
                    Text(symbol.prefix(2))
                        .font(.system(size:daySize, weight: .medium))
                        .frame(width: 38)
                        .opacity(1)
                }
            }
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.fixed(circleSize), spacing: gridSpacing),
                    count: 7
                ),
                spacing: gridSpacing
            ) {
                ForEach(gridDates, id: \.self) { d in
                    CalendarCircleView(
                        date: d,
                        baseDate: baseDate,
                        month: month,
                        deadline: deadline,
                        isDeadlineActive: isDeadlineActive,
                        todayColor: todayColor,
                        deadlineColor: deadlineColor,
                        circleSize: circleSize
                    )
                }
            }
        }
        //.background(Color.red)
    }
}

// MARK: - Individual Circle View

private struct CalendarCircleView: View {
    
    let date: Date
    let baseDate: Date
    let month: Int
    let deadline: Date
    let isDeadlineActive: Bool
    
    let todayColor: Color
    let deadlineColor: Color
    
    let circleSize: CGFloat
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return cal
    }
    
    var body: some View {
        let isCurrentMonth = calendar.component(.month, from: date) == month
        
        Circle()
            .fill(circleColor(for: date))
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(0.5), lineWidth: 0.7)
            )
            //.opacity(isCurrentMonth ? 1 : 0.3)
        .frame(width: circleSize, height: circleSize)
    }
    
    // MARK: - Coloring Logic
    
    private func circleColor(for d: Date) -> Color {
        let today = baseDate
        
        // Deadline
        if isDeadlineActive &&
            calendar.isDate(d, inSameDayAs: deadline) {
            return deadlineColor
        }
        
        // Today / selected base date
        if calendar.isDate(d, inSameDayAs: baseDate) {
            return todayColor
        }
        
        // Past dates in current month
        if calendar.compare(d, to: today, toGranularity: .day) == .orderedAscending &&
            calendar.component(.month, from: d) == month {
            return .primary
        }
        
        // Dates outside current month (excluding deadline)
        if calendar.component(.month, from: d) != month &&
            !calendar.isDate(d, inSameDayAs: deadline) {
            return .primary.opacity(0)
        }
        
        // Future dates
        return Color.gray.opacity(0.3)
    }
}

#Preview {
    MiniCalendarGridView(
        baseDate: Date(),
        startDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
        deadline: Calendar.current.date(byAdding: .day, value: 27, to: Date())!,
        isDeadlineActive: true,
        todayColor: .orange,
        deadlineColor: .cyan,
        daySize: 10,
        circleSize: 40,
        gridSpacing: 2
    )
    .padding()
    
}
