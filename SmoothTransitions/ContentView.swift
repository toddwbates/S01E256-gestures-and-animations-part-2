//
//  ContentView.swift
//  SmoothTransitions
//
//  Created by Chris Eidhof on 19.05.21.
//

import SwiftUI
import ComposableArchitecture

struct AppState : Equatable {
	let items : IdentifiedArrayOf<Item>
	var magnification: CGFloat = 1
	var currentID: Item.ID? = nil
	var fullscreenSize: CGSize = .zero
	var slowAnimations = false
	
	init(_ uuid: ()->UUID) {
		items = .init([Color.yellow,.red,.green,.purple].map {
			Item(id:uuid(),
				 color:$0,
				 cardSize: CGSize(width: 80, height: 100))
		})
	}
	
}

extension AppState {
	var currentCard : CardState? {
		items.first(where: {$0.id == self.currentID}).map(){
			CardState(id: $0.id,
					  color: $0.color,
					  cardSize: scaledSize(for: $0.cardSize),
					  show: true)
		}
	}
	
	func scaledSize(for cardSize: CGSize) -> CGSize {
		let size = cardSize + (fullscreenSize - cardSize) * magnification
		return CGSize(width: max(0, size.width), height: max(0, size.height))
	}

	var cards : IdentifiedArrayOf<CardState> { IdentifiedArrayOf( items.map({ CardState(with:$0, show: $0.id != self.currentID) })) }
}

enum AppAction : Equatable{
	case toggleAnimations
	case fullscreenSize(CGSize)
	case openAction(id:UUID,action:CardAction)
	case closeAction(action:CardAction)
}

struct AppEnvironment {
	let uuid: ()->UUID
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>() {state,action,_ in
	switch action {
	case .closeAction(action: .tapped):
		state.magnification = 0
		state.currentID = nil
	case let .openAction(id, .tapped):
		state.currentID = id
		state.magnification = 1
	case let .openAction(id, .pinchChanged(delta)):
		state.currentID = id
		state.magnification = max(0, min(1,1 - (2.0 - delta)))
	case .openAction(_, .pinchedEnded):
		if state.magnification > 0.3 {
			state.magnification = 1
		} else {
			state.magnification = 0
			state.currentID = nil
		}
	case let .closeAction(.pinchChanged(delta)):
		state.magnification =  max(0, min(1,delta))
	case .closeAction(.pinchedEnded):
		if state.magnification < 0.7 {
			state.magnification = 0
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
}

extension CardState {
	init(with item: Item, show:Bool) {
		id = item.id
		color = item.color
		cardSize = item.cardSize
		self.show = show
	}
}

extension Store where State : Equatable {
	func bind(_ action:Action) -> ()->() {
		return { ViewStore(self).send(action) }
	}
}

struct ContentView: View {
	let store: Store<AppState, AppAction>
	
	@Namespace var ns
	
	var body: some View {
		ZStack {
			HStack {
				ForEachStore(store.scope(state: \.cards,
										 action: AppAction.openAction)) {
					CardView(store: $0)
				}
			}
			IfLetStore(store.scope(state: \.currentCard, action:AppAction.closeAction(action:))) {
				CardView(store: $0)
					.zIndex(2)
				
			}
			WithViewStore(self.store) { viewStore in
				Color.clear.measure().onPreferenceChange(SizeKey.self) {
					viewStore.send(.fullscreenSize($0 ?? .zero))
				}
			}
		}
		.padding(50)
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.toolbar {
			Button("Slow Animations",action: self.store.bind(.toggleAnimations))
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView(store: .init(initialState: .init(UUID.incrementing), reducer: appReducer, environment: .init(uuid: UUID.incrementing)))
			.frame(width: 400, height: 100)
	}
}

