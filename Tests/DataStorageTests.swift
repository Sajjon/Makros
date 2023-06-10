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
	
	func testDataStoragePublic() {
		
		assertMacroExpansion(
			"""
			@DataStorage
			public struct DataHolder {
			}
			""",
			
			expandedSource:
			"""
			
			public struct DataHolder {
				public let data: Data
			}
			""",
			
			macros: testMacros,
			indentationWidth: .tab
		)
	}
	
	func testDataStorageImplicitInternal() {
		
		assertMacroExpansion(
			"""
			@DataStorage
			struct DataHolder {
			}
			""",
			
			expandedSource:
			"""
			
			struct DataHolder {
				let data: Data
			}
			""",
			
			macros: testMacros,
			indentationWidth: .tab
		)
	}
	
	func testDataStorageExplicitInternal() {
		
		assertMacroExpansion(
			"""
			@DataStorage
			internal struct DataHolder {
			}
			""",
			
			expandedSource:
			"""
			
			internal struct DataHolder {
				let data: Data
			}
			""",
			
			macros: testMacros,
			indentationWidth: .tab
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
			   macros: testMacros,
			   indentationWidth: .tab
		   )
	}
}
