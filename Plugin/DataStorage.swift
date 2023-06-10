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
		let access = declaration.modifiers?.first(where: \.isNeededAccessLevelModifier)

		return [
			"\(access)let data: Data",
			"\(access)init(data: Data) { self.data = data }"
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

extension DeclModifierSyntax {
	var isNeededAccessLevelModifier: Bool {
		switch self.name.tokenKind {
		case .keyword(.public): return true
		default: return false
		}
	}
}

extension SyntaxStringInterpolation {
	// It would be nice for SwiftSyntaxBuilder to provide this out-of-the-box.
	mutating func appendInterpolation<Node: SyntaxProtocol>(_ node: Node?) {
		if let node {
			appendInterpolation(node)
		}
	}
}
