import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) -> ExprSyntax {
		guard let argument = node.argumentList.first?.expression else {
			fatalError("compiler bug: the macro does not have any arguments")
		}
		
		return "(\(argument), \(literal: argument.description))"
	}
}

public struct DataStorageMacro: MemberMacro {
	public static func expansion<Declaration, Context>(
		of node: AttributeSyntax,
		providingMembersOf declaration: Declaration,
		in context: Context
	) throws -> [DeclSyntax] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
		return []
	}
}

//extension NewTypeMacro: MemberMacro {
//	public static func expansion<Declaration, Context>(
//		of node: AttributeSyntax,
//		providingMembersOf declaration: Declaration,
//		in context: Context
//	) throws -> [DeclSyntax] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
//		do {
//			guard
//				case .argumentList(let arguments) = node.argument,
//				arguments.count == 1,
//				let memberAccessExn = arguments.first?
//					.expression.as(MemberAccessExprSyntax.self),
//				let rawType = memberAccessExn.base?.as(IdentifierExprSyntax.self)
//			else {
//				throw CustomError.message(#"@NewType requires the raw type as an argument, in the form "RawType.self"."#)
//			}
//
//			guard let declaration = declaration.as(StructDeclSyntax.self) else {
//				throw CustomError.message("@NewType can only be applied to a struct declarations.")
//			}
//
//			let access = declaration.modifiers?.first(where: \.isNeededAccessLevelModifier)
//
//			return [
//				"\(access)typealias RawValue = \(rawType)",
//				"\(access)var rawValue: RawValue",
//				"\(access)init(_ rawValue: RawValue) { self.rawValue = rawValue }",
//			]
//		} catch {
//			print("--------------- throwing \(error)")
//			throw error
//		}
//	}
//}
