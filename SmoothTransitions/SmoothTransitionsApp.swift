//
//  SmoothTransitionsApp.swift
//  SmoothTransitions
//
//  Created by Chris Eidhof on 19.05.21.
//

import SwiftUI

@main
struct SmoothTransitionsApp: App {
    var body: some Scene {
        WindowGroup {
			ContentView(store: .init(initialState: .init(UUID.incrementing), reducer: appReducer, environment: .init(uuid: UUID.incrementing)))
        }
    }
}
