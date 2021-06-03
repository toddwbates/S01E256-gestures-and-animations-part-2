//
//  UtilTests.swift
//  SmoothTransitionsTests
//
//  Created by Todd Bates on 6/3/21.
//

import XCTest
import Foundation

@testable import SmoothTransitions

class UtilTests: XCTestCase {

    func testBind() throws {
		XCTAssertEqual(SmoothTransitions.bind(4, to: { $0 * 2 })(), 8)
    }

	func testMap() throws {
		XCTAssertEqual(SmoothTransitions.map({CGSize(width: $0,height: $0)}, {"\($0)"})(4), "(4.0, 4.0)")
	}
	
	func testCurry() throws {
		XCTAssertEqual(SmoothTransitions.curryA(CGSize.init(width:height:))(4)(5), CGSize(width:4,height:5))
		XCTAssertEqual(SmoothTransitions.curryB(CGSize.init(width:height:))(4)(5), CGSize(width:5,height:4))
	}
	
	func testAnimation() throws {
		var value = 0
		withAnimation(nil,{ value = $0 })(8)
		XCTAssertEqual(value, 8)
	}

	func testCGSizeExtension() throws {
		XCTAssertEqual(CGSize(width: 6, height: 8)/2, CGSize(width: 3, height: 4))
	}

	func testSizeKey() throws {
		var value : CGSize? = nil
		SizeKey.reduce(value: &value, nextValue: { CGSize(width: 6, height: 8) })
		XCTAssertEqual(value, CGSize(width: 6, height: 8))
		
		
		SizeKey.reduce(value: &value, nextValue: { CGSize(width: 1, height: 2) })
		XCTAssertEqual(value, CGSize(width: 6, height: 8))
	}

}
