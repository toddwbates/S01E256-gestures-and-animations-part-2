//
//  CardView.swift
//  SmoothTransitions
//
//  Created by Todd Bates on 5/31/21.
//

import SwiftUI
import ComposableArchitecture

struct CardState: Identifiable, Equatable {
	var id : UUID
	var color : Color
	var cardSize : CGSize
	var show : Bool
}

enum CardAction : Equatable{
	case tapped
	case pinchChanged(CGFloat)
	case pinchedEnded(CGFloat)
}

struct Item: Identifiable, Equatable {
	var id : UUID
	var color : Color
	var cardSize : CGSize
}

let cardReducer = Reducer<CardState, CardAction, ()> { _,_,_ in
	return .none
}

struct CardView: View {
	let store: Store<CardState, CardAction>
	
	
	var body: some View {
		WithViewStore(self.store) { viewStore in
			HStack {
				if viewStore.show {
					Text("Hello, World!")
						.padding()
						.frame(maxWidth: .infinity, maxHeight: .infinity)
						.background(
							RoundedRectangle(cornerRadius: 10)
								.fill(viewStore.color)
						)
				}
			}.frame(width: viewStore.cardSize.width, height: viewStore.cardSize.height)
			.gesture(MagnificationGesture()
						.onChanged() { viewStore.send(.pinchChanged($0)) }
						.onEnded() { viewStore.send(.pinchedEnded($0)) }
						.exclusively(before: TapGesture()
										.onEnded() { viewStore.send(.tapped) } ))
		}
	}
}

struct CardView_Previews: PreviewProvider {
	static var previews: some View {
		CardView(store: .init(initialState: .init(id:
													UUID.with(index: 1), color: .blue, cardSize: .init(width: 20, height: 40), show: true),
							  reducer: cardReducer,
							  environment: ()))
	}
}
