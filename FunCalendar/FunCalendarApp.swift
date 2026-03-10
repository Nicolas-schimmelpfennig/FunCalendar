//
//  FunCalendarApp.swift
//  FunCalendar
//
//  Created by Nicolas Schimmelpfennig on 04/12/2025.
//

import SwiftUI

@main
struct FunCalendarApp: App {
    var body: some Scene {
        WindowGroup {
            //ContentView()
            AppMainView(date: Date.now)
        }
    }
}
