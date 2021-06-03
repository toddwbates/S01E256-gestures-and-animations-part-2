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
						.onChanged({ action(.pinchChanged($0)) })
			   .onEnded({ action(.pinchEnded($0)) })
			   .exclusively(
				 before: TapGesture()
					.onEnded({ action(.tapped) })))

	}
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
		CardView(item: .init(id: .init(), color: .blue), action: { _ in })
    }
}
