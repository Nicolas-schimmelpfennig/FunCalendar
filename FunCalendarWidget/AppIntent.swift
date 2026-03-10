//
//  AppIntent.swift
//  FunCalendarWidget
//
//  Created by Nicolas Schimmelpfennig on 04/12/2025.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { 
        "Please open the app to configure your widget."
    }
}
