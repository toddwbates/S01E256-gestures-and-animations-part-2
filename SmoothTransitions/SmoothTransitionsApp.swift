//
//  SmoothTransitionsApp.swift
//  SmoothTransitions
//
//  Created by Todd Bates on 6/2/21.
//

import SwiftUI

@main
struct SmoothTransitionsApp: App {
    var body: some Scene {
        WindowGroup {
			ContentView(store: .init(initialState: .init(UUID.incrementing), reducer: appReducer, environment: .init()))
        }
    }
}
