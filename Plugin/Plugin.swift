#if canImport(SwiftCompilerPlugin)
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MakrosPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		StringifyMacro.self,
		DataStorageMacro.self,
	]
}
#endif
