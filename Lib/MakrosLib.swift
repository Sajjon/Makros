import Foundation

/// "Stringify" the provided value and produce a tuple that includes both the
/// original value as well as the source code that generated it.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(
	module: "MakrosPlugin",
	type: "StringifyMacro"
)
