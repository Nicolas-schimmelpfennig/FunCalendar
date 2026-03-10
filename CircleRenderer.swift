//
//  CircleRenderer.swift
//  FunCalendar
//
//  Created by Nicolas Schimmelpfennig on 11/02/2026.
//

import SwiftUI

struct CircleRenderer: View {
    let calendar: Calendar
    let d: Date
    let todayColor: Color
    let deadlineColor: Color
    let Deadline: Date
    let isDeadlineActive: Bool
    
    private var month: Int { calendar.component(.month, from: d) }
    
    var body: some View {
        let isCurrentMonth = calendar.component(.month, from: d) == month

        if isCurrentMonth {
            Circle()
                .fill(circleColor(for: d))
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.5), lineWidth: 0.7)
                )
                .frame(width: 40, height: 40)
        } else {
            Circle()
                .stroke(Color.primary.opacity(0.5), lineWidth: 0.7)
                .frame(width: 40, height: 40)
        }
    }
    private func circleColor(for d: Date) -> Color {
        let today = Date()
        
        // Deadline date → light blue
        if isDeadlineActive && calendar.isDate(d, inSameDayAs: Deadline) {
            return deadlineColor
        }
        
        // Selected day (always orange)
        if calendar.isDate(d, inSameDayAs: d) {
            return todayColor
        }
        
        // Past dates in the CURRENT month → black
        if calendar.compare(d, to: today, toGranularity: .day) == .orderedAscending &&
           calendar.component(.month, from: d) == month {
            return .primary
        }

        // Future dates in the current month → light gray
        return Color.gray.opacity(0.3)
    }
}

#Preview {
    CircleRenderer(calendar: .current, d: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 1))!, todayColor: .green, deadlineColor: .cyan, Deadline: Date(), isDeadlineActive: false)
}
