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
		store.send(.openAction(id: uuid1, action:.tapped)) {
			$0.currentID = uuid1
			$0.magnification = 1.0
		}
		store.send(.closeAction(action: .tapped)) {
			$0.currentID = nil
			$0.magnification = 0
		}
		store.send(.openAction(id: uuid1, action:.pinchChanged(CGFloat(1.3).nextDown))) {
			$0.currentID = uuid1
			$0.magnification = CGFloat(1.3).nextDown - 1
		}
		store.send(.openAction(id: uuid1, action:.pinchedEnded(CGFloat(1.3).nextDown))) {
			$0.currentID = nil
			$0.magnification = 0
		}
		store.send(.openAction(id: uuid1, action: .pinchChanged(1.3))) {
			$0.currentID = uuid1
			$0.magnification = CGFloat(1.3) - 1
		}
		store.send(.openAction(id: uuid1, action: .pinchedEnded(1.3))) {
			$0.currentID = uuid1
			$0.magnification = 1
		}
		store.send(.closeAction(action: .pinchChanged(0.7))) {
			$0.magnification = 0.7
		}
		store.send(.closeAction(action: .pinchedEnded(1.3))) {
			$0.magnification = 1
		}
		store.send(.closeAction(action: .pinchChanged(CGFloat(0.7).nextDown))) {
			$0.magnification = CGFloat(0.7).nextDown
		}
		store.send(.closeAction(action: .pinchedEnded(CGFloat(0.7).nextDown))) {
			$0.currentID = nil
			$0.magnification = 0
		}

	}
	
	func testView() throws {
		var state = AppState(UUID.incrementing)
		
		let closedView = ContentView(store: .init(initialState: state,
												   reducer: appReducer,
												   environment: .init(uuid: UUID.incrementing)))
		assertSnapshot(matching: closedView.toVC(), as: .image)
		
		state.currentID = UUID.with(index: 1)
		state.magnification = 1
		let openView = ContentView(store: .init(initialState: state,
												   reducer: appReducer,
												   environment: .init(uuid: UUID.incrementing)))
		assertSnapshot(matching: openView.toVC(), as: .image)
	}
}
