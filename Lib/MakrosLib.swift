import Foundation

@attached(member, names: named(data))
public macro DataStorage() = #externalMacro(
	module: "MakrosPlugin",
	type: "DataStorageMacro"
)
