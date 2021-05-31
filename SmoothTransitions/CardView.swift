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

struct CardView: View, Equatable {
	var item: Item
	
	var body: some View {
		Text("Hello, World!")
			.padding()
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(
				RoundedRectangle(cornerRadius: 10)
					.fill(item.color)
			)
	}
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
		CardView(item: .init(id: .init(), color: .blue))
    }
}
