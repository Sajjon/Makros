import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DataStorageMacro: MemberMacro {
	public static let defaultStorageName = "data"
}

extension DataStorageMacro {
	public static func expansion<Declaration, Context>(
		of node: AttributeSyntax,
		providingMembersOf declaration: Declaration,
		in context: Context
	) throws -> [DeclSyntax] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
		
		guard let declaration = declaration.as(StructDeclSyntax.self) else {
			throw Error.onlyApplicableToStruct
		}
		let access = declaration.modifiers?.first(where: \.isNeededAccessLevelModifier)
		
		let storageName = {
			guard
				case let .argumentList(arguments) = node.argument,
				let firstElement = arguments.first,
				let stringLiteral = firstElement.expression
					.as(StringLiteralExprSyntax.self),
				stringLiteral.segments.count == 1,
				case let .stringSegment(stringSegment)? = stringLiteral.segments.first
			else {
				return DataStorageMacro.defaultStorageName
			}
			return stringSegment.content.text
		}()
		
		return [
			"\(access)let \(raw: storageName): Data",
			"\(access)init(\(raw: storageName): Data) { self.\(raw: storageName) = \(raw: storageName) }"
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

