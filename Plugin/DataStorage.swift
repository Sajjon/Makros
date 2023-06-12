import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct DataStorageMacro: MemberMacro, ConformanceMacro {
	public static let defaultStorageName = "data"
	private static let macroArgumentStorageName = "named"
	private static let macroArgumentByteCount = "byteCount"
}


extension DataStorageMacro {

	public static func expansion<Declaration, Context>(
		of node: AttributeSyntax,
		providingConformancesOf declaration: Declaration,
		in context: Context
	) throws -> [(
		TypeSyntax,
		GenericWhereClauseSyntax?
	)] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {

		guard let declaration = declaration.as(StructDeclSyntax.self) else {
			context.diagnose(DataStorageMacroDiagnostic.requiresStruct.diagnose(at: declaration))
			return []
		}
		
		let inheritedTypes = declaration.inheritanceClause?.inheritedTypeCollection ?? []
		
		// If there is an explicit conformance to `DataProtocol` already, don't add conformance
		guard !inheritedTypes.contains(where: { $0.typeName.trimmedDescription == "DataProtocol" }) else {
			return []
		}
		
		return [
			(TypeSyntax(stringLiteral: "DataProtocol"), nil),
		]
		
	}
	
}



extension DataStorageMacro {
	public static func expansion<Declaration, Context>(
		of node: AttributeSyntax,
		providingMembersOf declaration: Declaration,
		in context: Context
	) throws -> [DeclSyntax] where Declaration : DeclGroupSyntax, Context : MacroExpansionContext {
		
		guard let declaration = declaration.as(StructDeclSyntax.self) else {
			context.diagnose(DataStorageMacroDiagnostic.requiresStruct.diagnose(at: declaration))
			return []
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
		
		let inheritedTypes = declaration.inheritanceClause?.inheritedTypeCollection ?? []
		
		let addDataProtocolSyntax = !inheritedTypes.contains(where: { $0.typeName.trimmedDescription == "DataProtocol" })
		
		
		let actualProp = "actual"
		let errorDescription = "Invalid byteCount, expected: \\(\(declaration.identifier.text).\(Self.macroArgumentByteCount)), but got: \\(\(actualProp))"
		
		let errorTypeName = "InvalidByteCountError"
		let invalidByteCountError = StructDeclSyntax(
			identifier: .identifier(errorTypeName),
			inheritanceClause: ["Error", "CustomStringConvertible"]
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
				input: [FunctionParameterSyntax(storageName, Data.self)],
				effectSpecifiers: isInitThrowing ? .throws : nil
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
		
		let dataProtocolConformanceSyntax: DeclSyntax = """
		\(access)subscript(position: Data.Index) -> Data.Element {
			\(raw: storageName)[position]
		}

		\(access)subscript(bounds: Range<Data.Index>) -> Data.SubSequence {
			\(raw: storageName)[bounds]
		}

		\(access)var regions: Data.Regions {
			\(raw: storageName).regions
		}

		\(access)var startIndex: Data.Index {
			\(raw: storageName).startIndex
		}

		\(access)var endIndex: Data.Index {
			\(raw: storageName).endIndex
		}

		\(access)typealias Regions = Data.Regions
		\(access)typealias Element = Data.Element
		\(access)typealias Index = Data.Index
		\(access)typealias SubSequence = Data.SubSequence
		\(access)typealias Indices = Data.Indices
		"""
		
		var declarations: [DeclSyntax] = [
			"\(access)let \(raw: storageName): \(Data.self)" as DeclSyntax,
			DeclSyntax(initializerDecl)
		]
		
		if addDataProtocolSyntax {
			declarations.insert(dataProtocolConformanceSyntax, at: 0)
		}
		
		if isInitThrowing {
			declarations.insert("\(access)static let \(raw: Self.macroArgumentByteCount) = \(byteCount)", at: 0)
			declarations.insert(DeclSyntax(invalidByteCountError), at: 0)
		}
	
		
		return declarations
	}
	
}

enum DataStorageMacroDiagnostic {
	case requiresStruct
}

extension DataStorageMacroDiagnostic: DiagnosticMessage {
	func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
		Diagnostic(node: Syntax(node), message: self)
	}
	
	var message: String {
		switch self {
		case .requiresStruct:
			return "'DataStorage' macro can only be applied to a struct"
		}
	}
	
	var severity: DiagnosticSeverity { .error }
	
	var diagnosticID: MessageID {
		MessageID(domain: "Makros", id: "Data.\(self)")
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

extension ParameterClauseSyntax: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: FunctionParameterSyntax...) {
		self.init(parameterList: .init(elements))
	}
}

extension TypeInheritanceClauseSyntax: ExpressibleByArrayLiteral {
	public init(arrayLiteral elements: String...) {
		self.init(inheritedTypeCollection: .init(elements.enumerated().map { (offset, element) in
				.init(typeName: TypeSyntax(stringLiteral: element), trailingComma: (offset == elements.count - 1) ? nil : .commaToken())
		}))
	}
}

extension FunctionParameterSyntax {
	init<ParameterType>(_ firstName: String, _ type: ParameterType) {
		self.init(
			firstName: .identifier(firstName),
			colon: .colonToken(trailingTrivia: .space),
			type: "\(raw: type)" as TypeSyntax
		)
	}
}
