import Foundation
import MakrosPlugin

@attached(member, names: named(init(data:)))
public macro DataStorage(named: String = DataStorageMacro.defaultStorageName) = #externalMacro(
	module: "MakrosPlugin",
	type: "DataStorageMacro"
)
