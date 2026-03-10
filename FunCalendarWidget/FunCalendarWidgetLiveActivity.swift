//
//  FunCalendarWidgetLiveActivity.swift
//  FunCalendarWidget
//
//  Created by Nicolas Schimmelpfennig on 04/12/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FunCalendarWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FunCalendarWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FunCalendarWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FunCalendarWidgetAttributes {
    fileprivate static var preview: FunCalendarWidgetAttributes {
        FunCalendarWidgetAttributes(name: "World")
    }
}

extension FunCalendarWidgetAttributes.ContentState {
    fileprivate static var smiley: FunCalendarWidgetAttributes.ContentState {
        FunCalendarWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FunCalendarWidgetAttributes.ContentState {
         FunCalendarWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FunCalendarWidgetAttributes.preview) {
   FunCalendarWidgetLiveActivity()
} contentStates: {
    FunCalendarWidgetAttributes.ContentState.smiley
    FunCalendarWidgetAttributes.ContentState.starEyes
}
