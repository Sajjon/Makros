import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

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
		
		let dataStorageParam = FunctionParameterSyntax(
			firstName: .identifier(storageName),
			colon: .colonToken(trailingTrivia: .space),
			type: "\(raw: Data.self)" as TypeSyntax
		)
		
		let actualProp = "actual"
		let errorDescription = "Invalid byteCount, expected: \\(\(declaration.identifier.text).\(Self.macroArgumentByteCount)), but got: \\(\(actualProp))"
		
		let errorTypeName = "InvalidByteCountError"
		let invalidByteCountError = StructDeclSyntax(
			identifier: .identifier(errorTypeName),
			inheritanceClause: .init(inheritedTypeCollection: [
				.init(typeName: "Error" as TypeSyntax, trailingComma: .commaToken()),
				.init(typeName: "CustomStringConvertible" as TypeSyntax),
			])
		) {
			.init([
				.init(decl: "let \(raw: actualProp): \(Int.self)" as DeclSyntax),
				.init(decl: "var description: \(String.self) { \"\(raw: errorDescription)\" }" as DeclSyntax),
			])
		}

		let isInitThrowing = byteCount != nil
		let initializerDecl = InitializerDeclSyntax(
			leadingTrivia: access == nil ? .newline : .tab,
			modifiers: access.map { [$0] },
			signature: .init(
				input: [dataStorageParam],
				effectSpecifiers: isInitThrowing ?> .throws
			),
			bodyBuilder: {
				if isInitThrowing {
					"""
					guard \(raw: storageName).count == Self.\(raw: Self.macroArgumentByteCount) else {
						throw \(raw: errorTypeName)(\(raw: actualProp): \(raw: storageName).count)
					}
					"""
				}
				"self.\(raw: storageName) = \(raw: storageName)"
			}
		)

		var declarations: [DeclSyntax] = [
			"\(access)let \(raw: storageName): \(Data.self)" as DeclSyntax,
			DeclSyntax(initializerDecl)
		]
		
		if isInitThrowing {
			declarations.insert("\(access)static let \(raw: Self.macroArgumentByteCount) = \(byteCount)", at: 0)
			declarations.insert(DeclSyntax(invalidByteCountError), at: 0)
		}
		
		return declarations
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


extension FunctionEffectSpecifiersSyntax {
	static let `throws` = Self(throwsSpecifier: "throws")
}

infix operator ?>
func ?><Value>(condition: Bool, value: Value) -> Value? {
	guard condition else {
		return nil
	}
	return value
}

extension ParameterClauseSyntax: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: FunctionParameterSyntax...) {
		self.init(parameterList: .init(elements))
	}
}
