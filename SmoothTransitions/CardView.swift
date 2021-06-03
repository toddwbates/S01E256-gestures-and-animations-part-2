//
//  CardView.swift
//  SmoothTransitions
//
//  Created by Todd Bates on 5/31/21.
//

import SwiftUI

struct Item: Identifiable, Equatable {
	var id : UUID
	var color : Color
}

struct CardView: View {
	let item: Item
	let action :(CardAction)->()
	
	var body: some View {
		Text("Hello, World!")
			.padding()
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(
				RoundedRectangle(cornerRadius: 10)
					.fill(item.color)
			)
			.gesture(MagnificationGesture()
						.onChanged(map(CardAction.pinchChanged,action))
			   .onEnded(map(CardAction.pinchEnded,action))
			   .exclusively(
				 before: TapGesture()
					.onEnded(bind(.tapped,to: action))))

	}
}

struct CardView_Previews: PreviewProvider {
	static let no_op : (CardAction)->() = { _ in }
	
    static var previews: some View {
		CardView(item: .init(id: .init(), color: .blue), action: no_op)
		CardView(item: .init(id: .init(), color: .red), action: no_op)
    }
}
