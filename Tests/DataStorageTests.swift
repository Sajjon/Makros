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

				public init(data: Data) {
					self.data = data
				}
			}
			""",
			
			macros: testMacros,
			indentationWidth: .tab
		)
	}
	
	func testDataStoragePublicExplicitNamedData() {
		
		assertMacroExpansion(
			"""
			@DataStorage(named: data)
			public struct DataHolder {
			}
			""",
			
			expandedSource:
			"""
			
			public struct DataHolder {
				public let data: Data

				public init(data: Data) {
					self.data = data
				}
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
				init(data: Data) {
					self.data = data
				}
			}
			""",
			
			macros: testMacros,
			indentationWidth: .tab
		)
	}
	
	func testDataStorageNamedExplicitInternal() {
		
		assertMacroExpansion(
			"""
			@DataStorage(named: "foo")
			internal struct DataHolder {
			}
			""",
			
			expandedSource:
			"""
			
			internal struct DataHolder {
				let foo: Data
				init(foo: Data) {
					self.foo = foo
				}
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
	
	func testDataStoragePublicExplicitNamedDataByteCount32() {
		
		assertMacroExpansion(
			"""
			@DataStorage(named: data, byteCount: 32)
			public struct DataHolder {
			}
			""",
			
			expandedSource:
			"""
			
			public struct DataHolder {
				struct InvalidByteCountError: Error, CustomStringConvertible {
					let actual: Int
					var description: String {
						"Invalid byteCount, expected: \\(DataHolder.byteCount), but got: \\(actual)"
					}
				}
				public static let byteCount = 32
				public let data: Data

				public init(data: Data) throws {
					guard data.count == Self.byteCount else {
						throw InvalidByteCountError(actual: data.count)
					}
					self.data = data
				}
			}
			""",
			
			macros: testMacros,
			indentationWidth: .tab
		)
	}
}
