//
//  SmoothTransitionsTests.swift
//  SmoothTransitionsTests
//
//  Created by Todd Bates on 5/31/21.
//

import XCTest
import SwiftUI
import SnapshotTesting
import ComposableArchitecture

@testable import SmoothTransitions

extension SwiftUI.View {
	func toVC() -> NSView {
		let vc = NSHostingView(rootView: self)
		vc.frame = CGRect(x: 0, y: 0, width: 400, height: 100)
		return vc
	}
}

class SmoothTransitionsTests: XCTestCase {
	func testExample() throws {
		let uuid1 = UUID.with(index:1)
		let store = TestStore(
			initialState: AppState(UUID.incrementing),
			reducer: appReducer,
			environment: .init(uuid: UUID.incrementing)
		)
		
		store.send(.fullscreenSize(.init(width: 400, height: 100))) {
			$0.fullscreenSize = CGSize(width: 400, height: 100)
		}
		store.send(.toggleAnimations) {
			$0.slowAnimations.toggle()
		}
		store.send(.open(uuid1, .tapped)) {
			$0.current = .fullsize(uuid1)
		}
		store.send(.close(uuid1, .tapped)) {
			$0.current = .none
		}
		store.send(.open(uuid1, .pinchChanged(1.5))) {
			$0.current = .scale(uuid1,0.5)
		}
		store.send(.open(uuid1, .pinchEnded(1.5))) {
			$0.current = .fullsize(uuid1)
		}
		store.send(.close(uuid1, .pinchChanged(0.5))) {
			$0.current = .scale(uuid1,0.5)
		}
		store.send(.close(uuid1, .pinchEnded(CGFloat(0.7).nextDown))) {
			$0.current = .none
		}
		store.send(.close(uuid1, .pinchEnded(0.7))) {
			$0.current = .fullsize(uuid1)
		}
		store.send(.open(uuid1, .pinchEnded(CGFloat(0.3).nextDown))) {
			$0.current = .none
		}
		store.send(.open(uuid1, .pinchEnded(0.3))) {
			$0.current = .fullsize(uuid1)
		}

	}
	
	func testView() throws {
		var state = AppState(UUID.incrementing)
		
		let closedView = ContentView(store: .init(initialState: state,
												   reducer: appReducer,
												   environment: .init(uuid: UUID.incrementing)))
		assertSnapshot(matching: closedView.toVC(), as: .image)
		
		state.current = .fullsize(UUID.with(index: 1))
		let openView = ContentView(store: .init(initialState: state,
												   reducer: appReducer,
												   environment: .init(uuid: UUID.incrementing)))
		assertSnapshot(matching: openView.toVC(), as: .image)
		
		state.current = .scale(UUID.with(index: 1), 0.5)
		let scaledVIew = ContentView(store: .init(initialState: state,
												   reducer: appReducer,
												   environment: .init(uuid: UUID.incrementing)))
		assertSnapshot(matching: scaledVIew.toVC(), as: .image)

	}
}
