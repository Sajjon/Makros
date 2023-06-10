import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import MakrosPlugin
import XCTest

private let testMacros: [String: Macro.Type] = [
	"DataStorage" : DataStorageMacro.self,
]

final class DataStoragePluginTests: XCTestCase {
	
	func testDataStorage() {
		
		assertMacroExpansion(
			"""
			@DataStorage
			struct DataHolder {
			}
			""",
			
			expandedSource:
			"""
			
			struct DataHolder {
			}
			""",
			
			macros: testMacros
		)
	}
}
