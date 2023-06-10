import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DataStorageMacro: MemberMacro {
	public static func expansion<Declaration, Context>(
		of node: AttributeSyntax,
		providingMembersOf declaration: Declaration,
		in context: Context
	) throws -> [DeclSyntax] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
		guard let declaration = declaration.as(StructDeclSyntax.self) else {
			throw Error.onlyApplicableToStruct
		}
		return [
			"let data: Data"
		]
	}
	
	enum Error: Swift.Error, CustomStringConvertible {
		static let onlyApplicableToStruct: Self = .message("@DataStorage can only be applied to a struct")
		case message(String)
		
		var description: String {
			switch self {
			case .message(let text):
				return text
			}
		}
	}

}
