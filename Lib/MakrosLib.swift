import Foundation

@attached(member, names: named(data), named(init(data:)))
public macro DataStorage() = #externalMacro(
	module: "MakrosPlugin",
	type: "DataStorageMacro"
)
