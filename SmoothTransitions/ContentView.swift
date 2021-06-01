//
//  ContentView.swift
//  SmoothTransitions
//
//  Created by Chris Eidhof on 19.05.21.
//

import SwiftUI
import ComposableArchitecture

struct AppState : Equatable {
	let items : [Item]
	let cardSize = CGSize(width: 80, height: 100)
	var magnification: CGFloat = 1
	var isFullScreen = false
	var currentID: Item.ID? = nil
	var fullscreenSize: CGSize = .zero
	var slowAnimations = false
	
	init(_ uuid: ()->UUID) {
		items = [Color.yellow,.red,.green,.purple].map { Item(id:uuid(), color:$0) }
	}
}

enum AppAction : Equatable{
	case closingTapped
	case openTapped(Item.ID)
	case openPinchedChanged(Item.ID, CGFloat)
	case openPinchedEnded
	case closePinchedChanged(CGFloat)
	case closePinchedEnded
	case toggleAnimations
	case fullscreenSize(CGSize)
}

struct AppEnvironment {
	let uuid: ()->UUID
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>() {state,action,_ in
	switch action {
	case .closingTapped:
		state.magnification = 0
		state.isFullScreen = false
		state.currentID = nil
	case let .openTapped(id):
		state.currentID = id
		state.magnification = 1
		state.isFullScreen = true
	case let .openPinchedChanged(id,delta):
		state.currentID = id
		state.magnification = max(0, min(1,1 - (2.0 - delta)))
	case .openPinchedEnded:
		if state.magnification > 0.3 {
			state.magnification = 1
			state.isFullScreen = true
		} else {
			state.magnification = 0
			state.isFullScreen = false
			state.currentID = nil
		}
	case let .closePinchedChanged(delta):
		state.magnification =  max(0, min(1,delta))
	case .closePinchedEnded:
		if state.magnification < 0.7 {
			state.magnification = 0
			state.isFullScreen = false
			state.currentID = nil
		} else {
			state.magnification = 1
		}
	case .toggleAnimations:
		state.slowAnimations.toggle()
	case let .fullscreenSize(endSize):
		state.fullscreenSize = endSize
		
	}
	
	return .none
}


extension ViewStore where State == AppState, Action == AppAction {
	
	var animation: Animation {
		Animation.default.speed(state.slowAnimations ? 0.2 : 1)
	}
	
	func isClosing(_ id: Item.ID)->Bool { return id == state.currentID && state.isFullScreen }
	
	func onTap(for id: Item.ID) -> ()->() {
		return {
			withAnimation(self.animation) {
				self.send(self.isClosing(id) ? AppAction.closingTapped  : .openTapped(id))
			   }
		}
	}
	
	func onPinchChange(for id: Item.ID) -> (CGFloat)->() {
		return { self.send(self.isClosing(id) ? .closePinchedChanged($0) : .openPinchedChanged(id,$0)) }
	}

	func onPinchEnded(for id: Item.ID) -> (CGFloat)->() {
		return { _ in
			withAnimation(self.animation) {
				self.send(self.isClosing(id) ? .closePinchedEnded : .openPinchedEnded)
			   }
		}
	}

	func gesture(for id: Item.ID) -> some Gesture {
		let pinch = MagnificationGesture()
			.onChanged(self.onPinchChange(for: id))
			.onEnded(self.onPinchEnded(for: id))
		let tap = TapGesture()
			.onEnded(self.onTap(for: id))
		return pinch.exclusively(before: tap)
	}
	
	func scaledSize() -> CGSize {
		let size = state.cardSize + (state.fullscreenSize - state.cardSize) * state.magnification
		return CGSize(width: max(0, size.width), height: max(0, size.height))
	}
		
	var currentItem : Item? {
		state.items.first(where: { $0.id == state.currentID })
	}
}

struct ContentView: View {
	let store: Store<AppState, AppAction>
	
	@Namespace var ns
	
	var body: some View {
		WithViewStore(self.store) { viewStore in
			ZStack {
				HStack {
					ForEach(viewStore.items) { item in
						let isSelected = viewStore.currentID != item.id
						ZStack {
							if isSelected {
								CardView(item: item)
									.matchedGeometryEffect(id: item.id, in: ns, properties: [.frame,.position, .size])
							}
						}
						.zIndex(isSelected ? 2 : 1)
						.gesture(viewStore.gesture(for: item.id))
						.frame(width: viewStore.cardSize.width, height: viewStore.cardSize.height)
					}
				}
				
				if let item = viewStore.currentItem {
					let s = viewStore.scaledSize()
					CardView(item: item)
						.matchedGeometryEffect(id: item.id, in: ns, properties: [.frame,.position, .size])
						.frame(width: s.width, height: s.height)
						.zIndex(2)
						.gesture(viewStore.gesture(for: item.id))
				}
				
				Color.clear.measure().onPreferenceChange(SizeKey.self) {
					viewStore.send(.fullscreenSize($0 ?? .zero))
				}
			}
			.padding(50)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.toolbar {
				Button("Slow Animations") { viewStore.send(.toggleAnimations) }
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(store: .init(initialState: .init(UUID.incrementing), reducer: appReducer, environment: .init(uuid: UUID.incrementing)))
	}
}

