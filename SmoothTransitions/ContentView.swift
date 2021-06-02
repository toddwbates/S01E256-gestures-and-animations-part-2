//
//  ContentView.swift
//  SmoothTransitions
//
//  Created by Chris Eidhof on 19.05.21.
//

import SwiftUI
import ComposableArchitecture

enum Current : Equatable{
	case none
	case scale(UUID,CGFloat)
	case fullsize(UUID)
}

extension Current {
	var id : Item.ID? {
		switch self {
		case .none:
			return nil
		case let .scale(id, _):
			return id
		case let .fullsize(id):
			return id
		}
	}
	
	func scaledSize(with fullscreenSize: CGSize) -> CGSize {
		var size = CGSize(width: 80, height: 100)
		switch self {
		case .none:
			break
		case let .scale(_, delta):
			size = size + (fullscreenSize - size) * delta
			size = CGSize(width: max(0, size.width), height: max(0, size.height))
		case .fullsize(_):
			size = fullscreenSize
		}
		
		return size
	}

}

struct AppState : Equatable {
	var items : [Item]
	var current = Current.none
	var fullscreenSize: CGSize = .zero
	var slowAnimations = false
	
	init(_ uuid: ()->UUID) {
		items = [Color.yellow,.red,.green,.purple].map { Item(id:uuid(), color:$0) }
	}
}

enum CardAction : Equatable{
	case tapped
	case pinchChanged(CGFloat)
	case pinchEnded(CGFloat)
}

enum AppAction : Equatable{
	case open(Item.ID, CardAction)
	case close(Item.ID, CardAction)
	case toggleAnimations
	case fullscreenSize(CGSize)
}

struct AppEnvironment {
	let uuid: ()->UUID
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>() {state,action,_ in
	switch action {
	case let .open(id, .tapped):
		state.current = .fullsize(id)
	case let .close(id, .tapped):
		state.current = .none

	case let .open(id,.pinchChanged(delta)):
		state.current = .scale(id, max(0, min(1,1 - (2.0 - delta))))
	case let .close(id,.pinchChanged(delta)):
		state.current = .scale(id, max(0, min(1,delta)))
		
	case let .open(id,.pinchEnded(delta)):
		state.current = delta < 0.3 ? .none : .fullsize(id)
	case let .close(id,.pinchEnded(delta)):
		state.current = delta < 0.7 ? .none : .fullsize(id)

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
	
	func onTap(for id: Item.ID, action:@escaping (Item.ID, CardAction)->AppAction) -> ()->() {
		return {
			withAnimation(self.animation) {
				self.send(action(id,.tapped))
			}
		}
	}
		
	func onDelta(for id: Item.ID, action:@escaping (Item.ID, CardAction)->AppAction,_ cardAction:@escaping (CGFloat)->CardAction) -> (CGFloat)->() {
		return { delta in
			withAnimation(self.animation) {
				self.send(action(id,cardAction(delta)))
			}
		}
	}
	
	func gesture(for id: Item.ID, action:@escaping (Item.ID, CardAction)->AppAction) -> some Gesture {
		let pinch = MagnificationGesture()
			.onChanged(self.onDelta(for: id, action: action, CardAction.pinchChanged))
			.onEnded(self.onDelta(for: id, action: action, CardAction.pinchEnded))
		let tap = TapGesture()
			.onEnded(self.onTap(for: id, action: action))
		return pinch.exclusively(before: tap)
	}
	
}

struct ContentView: View {
	let store: Store<AppState, AppAction>
	
	@Namespace var ns
	
	var body: some View {
		WithViewStore(self.store) { viewStore in
			ZStack {
				let selectedItem = viewStore.items.first(where: { $0.id == viewStore.current.id })
				
				HStack {
					ForEach(viewStore.items) { item in
						let isSelected = selectedItem == item
						ZStack {
							if !isSelected {
								CardView(item: item)
									.matchedGeometryEffect(id: item.id, in: ns)
							}
						}
						.zIndex(isSelected ? 2 : 1)
						.gesture(viewStore.gesture(for: item.id, action: AppAction.open))
						.frame(width: 80, height: 100)
					}
				}
				
				if let item = selectedItem {
					let s = viewStore.current.scaledSize(with: viewStore.fullscreenSize)
					CardView(item: item)
						.matchedGeometryEffect(id: item.id, in: ns)
						.frame(width: s.width, height: s.height)
						.zIndex(2)
						.gesture(viewStore.gesture(for: item.id, action: AppAction.close))
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

