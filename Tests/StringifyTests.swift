import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MakrosPlugin
import XCTest

var testMacros: [String: Macro.Type] = [
	"stringify" : StringifyMacro.self,
]

final class StringifyPluginTests: XCTestCase {
	
	func testStringify() {
		
		let sf: SourceFileSyntax =
			#"""
			let a = #stringify(x + y)
			let b = #stringify("Hello, \(name)")
			"""#
		
		let context = BasicMacroExpansionContext(
			sourceFiles: [
				sf: .init(
					moduleName: "DummyModule",
					fullFilePath: "DummyFile.swift"
				)
			]
		)
		
		let transformedSF = sf.expand(
			macros: testMacros,
			in: context
		)
	
		XCTAssertEqual(
			transformedSF.description,
			#"""
			let a = (x + y, "x + y")
			let b = ("Hello, \(name)", #""Hello, \(name)""#)
			"""#
		)
		
	}
	
}
