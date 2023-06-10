import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import MakrosPlugin
import XCTest

private let testMacros: [String: Macro.Type] = [
	"stringify" : StringifyMacro.self,
]

final class StringifyPluginTests: XCTestCase {
	
	func testStringify() {
		
		assertMacroExpansion(
			"""
			#stringify(x + y)
			""",
			
			expandedSource:
			"""
			(x + y, "x + y")
			""",
			
			macros: testMacros
		)
	}
}