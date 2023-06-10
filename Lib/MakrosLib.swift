import Foundation
import MakrosPlugin

@attached(member, names: named(init(data:)), arbitrary)
public macro DataStorage(
	named: String = DataStorageMacro.defaultStorageName,
	byteCount: UInt? = nil
) = #externalMacro(
	module: "MakrosPlugin",
	type: "DataStorageMacro"
)
