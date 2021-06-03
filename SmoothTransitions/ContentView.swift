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
		if case .fullsize(_) = self {
			size = fullscreenSize
		} else if case let .scale(_, delta) = self {
			size = size + (fullscreenSize - size) * delta
			size = CGSize(width: max(0, size.width), height: max(0, size.height))
		}
		
		return size
	}

}

struct AppState : Equatable {
	var items : [Item]
	var current = Current.none
	var fullscreenSize: CGSize = .zero
	var animationnDuration = 0.2
	
	init(_ items: [Item]) {
		self.items = items
	}
	
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
	case fullscreenSize(CGSize?)
}

struct AppEnvironment {
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
		state.animationnDuration = state.animationnDuration == 1 ? 0.2 : 1
	case let .fullscreenSize(endSize):
		state.fullscreenSize = endSize ?? .zero
		
	}
	
	return .none
}

extension ViewStore where State == AppState, Action == AppAction {
		
	func onTap(for id: Item.ID, action:@escaping (Item.ID, CardAction)->AppAction) -> (CardAction)->() {
		let a2 = map(curryA(action)(id),self.send)
		let animation = Animation.default.speed(state.animationnDuration)
		return withAnimation(animation,a2)
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
								CardView(item: item, action: viewStore.onTap(for: item.id,action: AppAction.open))
									.matchedGeometryEffect(id: item.id, in: ns)
							}
						}
						.zIndex(isSelected ? 2 : 1)
						.frame(width: 80, height: 100)
					}
				}
				
				if let item = selectedItem {
					let s = viewStore.current.scaledSize(with: viewStore.fullscreenSize)
					CardView(item: item, action: viewStore.onTap(for: item.id,action: AppAction.close))
						.matchedGeometryEffect(id: item.id, in: ns)
						.frame(width: s.width, height: s.height)
						.zIndex(2)
				}
				
				Color.clear.measure().onPreferenceChange(SizeKey.self) {
					viewStore.send(.fullscreenSize($0))
				}
			}
			.padding(50)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.toolbar {
				Button("Slow Animations",action: bind(.toggleAnimations,to: viewStore.send))
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		let uuid = UUID.incrementing
		ContentView(store: .init(initialState: .init([Color.red,.green,.blue].map { Item(id:uuid(), color:$0) }),
								 reducer: appReducer,
								 environment: .init()))
	}
}

