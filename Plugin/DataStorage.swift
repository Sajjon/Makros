import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DataStorageMacro: MemberMacro {
	public static let defaultStorageName = "data"
	private static let macroArgumentStorageName = "named"
	private static let macroArgumentByteCount = "byteCount"
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
				let firstElement = arguments.first(where: { $0.label?.text == DataStorageMacro.macroArgumentStorageName }),
				let stringLiteral = firstElement.expression
					.as(StringLiteralExprSyntax.self),
				stringLiteral.segments.count == 1,
				case let .stringSegment(stringSegment)? = stringLiteral.segments.first
			else {
				return DataStorageMacro.defaultStorageName
			}
			return stringSegment.content.text
		}()
		
		let byteCount: TokenSyntax? = {
			guard
				case let .argumentList(arguments) = node.argument,
				let firstElement = arguments.first(where: { $0.label?.text == Self.macroArgumentByteCount }),
				let integerLiteral = firstElement.expression
					.as(IntegerLiteralExprSyntax.self)
			else {
				return nil
			}
			return integerLiteral.digits
		}()
		
		let initializer: DeclSyntax = {
			guard let byteCount else {
				return "\(access)init(\(raw: storageName): Data) { self.\(raw: storageName) = \(raw: storageName) }"
			}
			let errorDescription = "Invalid byteCount, expected: \\(\(declaration.identifier.text).\(Self.macroArgumentByteCount)), but got: \\(actual)"
			return """
			public static let \(raw: Self.macroArgumentByteCount) = \(byteCount)
			struct InvalidByteCount: Swift.Error, CustomStringConvertible {
				let actual: Int
				var description: String {
					"\(raw: errorDescription)"
				}
			}
			\(access)init(\(raw: storageName): Data) throws {
				guard \(raw: storageName).count == Self.\(raw: Self.macroArgumentByteCount) else {
					throw InvalidByteCount(actual: \(raw: storageName).count)
				}
				self.\(raw: storageName) = \(raw: storageName)
			}
			"""
		}()
		
		return [
			"\(access)let \(raw: storageName): Data",
			initializer
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

