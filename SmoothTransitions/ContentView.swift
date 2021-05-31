//
//  ContentView.swift
//  SmoothTransitions
//
//  Created by Chris Eidhof on 19.05.21.
//

import SwiftUI
import ComposableArchitecture

struct AppState : Equatable {
	let items = [Color.yellow,Color.red,Color.green,Color.purple].map { Item(id:UUID(), color:$0) }
	let cardSize = CGSize(width: 80, height: 100)
	var magnification: CGFloat = 1
	var isFullScreen = false
	var currentID: Item.ID? = nil
	var fullscreenSize: CGSize = .zero
	var slowAnimations = false
}

enum AppAction{
	case closingTapped
	case openTapped(Item.ID)
	case openPinchedChanged(Item.ID, CGFloat)
	case openPinchedEnded
	case closePinchedChanged(CGFloat)
	case closePinchedEnded
	case toggleAnimations
	case fullscreenSize(CGSize?)
}

let appReducer = Reducer<AppState, AppAction, ()>() {state,action,_ in
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
		state.fullscreenSize = endSize ?? .zero
		
	}
	
	return .none
}

extension CGSize {
	static func /(lhs: Self, rhs: CGFloat) -> Self {
		CGSize(width: lhs.width/rhs, height: lhs.height/rhs)
	}
	
	static func *(lhs: Self, rhs: CGFloat) -> Self {
		CGSize(width: lhs.width*rhs, height: lhs.height*rhs)
	}
	
	static func -(lhs: Self, rhs: Self) -> Self {
		CGSize(width: lhs.width-rhs.width, height: lhs.height-rhs.height)
	}
	
	static func +(lhs: Self, rhs: Self) -> Self {
		CGSize(width: lhs.width+rhs.width, height: lhs.height+rhs.height)
	}
}

struct SizeKey: PreferenceKey {
	static var defaultValue: CGSize?
	static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
		value = value ?? nextValue()
	}
}

extension View {
	func measure() -> some View {
		background(GeometryReader { proxy in
			Color.clear.preference(key: SizeKey.self, value: proxy.size)
		})
	}
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
	
	func size(for id: Item.ID) -> CGSize {
		guard id == state.currentID else { return state.cardSize }
		return interpolatedSize(factor: state.magnification)
	}
	
	func interpolatedSize(factor: CGFloat) -> CGSize {
		let size = state.cardSize + (state.fullscreenSize - state.cardSize) * factor
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
					let s = viewStore.size(for:item.id)
					CardView(item: item)
						.matchedGeometryEffect(id: item.id, in: ns, properties: [.frame,.position, .size])
						.frame(width: s.width, height: s.height)
						.zIndex(2)
						.gesture(viewStore.gesture(for: item.id))
				}
				
				Color.clear.measure().onPreferenceChange(SizeKey.self, perform: {
					viewStore.send(.fullscreenSize($0))
				})
			}
			.padding(50)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.toolbar {
				Button("Slow Animations") { viewStore.send(.toggleAnimations)}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(store: .init(initialState: .init(), reducer: appReducer, environment: {}()))
	}
}

