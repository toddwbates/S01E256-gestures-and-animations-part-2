//
//  Util.swift
//  SmoothTransitions
//
//  Created by Todd Bates on 5/31/21.
//

import Foundation
import SwiftUI

extension UUID {
  /// A deterministic, auto-incrementing "UUID" generator for testing.
  static var incrementing: () -> UUID {
	var uuid = 0
	return {
	  defer { uuid += 1 }
	  return UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", uuid))")!
	}
  }

	static func with(index uuid: Int) -> UUID {
		return UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012x", uuid))")!
	}

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

