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
			public struct DataHolder {
			}
			""",
			
			expandedSource:
			"""
			
			public struct DataHolder {
			    let data: Data
			}
			""",
			
			macros: testMacros
		)
	}
	
	func testDiagnosticOnlyApplicableToStruct() {
		assertMacroExpansion(
			   """
			   @DataStorage
			   enum MyEnum {
			   }
			   """,
			   expandedSource: """

			   enum MyEnum {
			   }
			   """,
			   diagnostics: [
				   DiagnosticSpec(message: "@DataStorage can only be applied to a struct", line: 1, column: 1)
			   ],
			   macros: testMacros
		   )
	}
}
