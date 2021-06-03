//
//  Util.swift
//  SmoothTransitions
//
//  Created by Todd Bates on 5/31/21.
//

import Foundation
import SwiftUI

func bind<A, C>(_ a:A,to f: @escaping (A) -> C) -> () -> C {
   { f(a) }
}

func map<A,B,C>(_ g:@escaping (A)->B,_ f:@escaping (B)->C) -> (A)->C {
	{ f(g($0)) }
}

func curryA<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
   { a in { b in f(a, b) } }
}

func curryB<A, B, C>(_ f: @escaping (A, B) -> C) -> (B) -> (A) -> C {
   { b in { a in f(a, b) } }
}

func withAnimation<A,Result>(_ animation: Animation? = .default, _ body:@escaping (A) -> Result) -> (A)->Result {
	{ value in withAnimation(animation,{ body(value) }) }
}

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
		// first value wins
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

