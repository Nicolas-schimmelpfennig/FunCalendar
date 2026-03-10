//
//  FunCalendarWidgetBundle.swift
//  FunCalendarWidget
//
//  Created by Nicolas Schimmelpfennig on 04/12/2025.
//

import WidgetKit
import SwiftUI

@main
struct FunCalendarWidgetBundle: WidgetBundle {
    var body: some Widget {
        FunCalendarWidget()
        FunCalendarWidgetControl()
        FunCalendarWidgetLiveActivity()
    }
}
