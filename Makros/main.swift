import MakrosLib
import Foundation

@DataStorage
struct SimpleData {}

@DataStorage(byteCount: 4)
struct DataHolder {}

assert(try! DataHolder(data: Data([0xde, 0xad, 0xbe, 0xef])).data.count == 4)
print("OK!")
do {
	_ = try DataHolder(data: Data([0xde, 0xad, 0xbe, 0xef, 0xff]))
	assertionFailure("❌ Unexpectedly did NOT throw")
} catch {
	print("✅ Got expected error: \(String(describing: error))")
}

do {
	_ = try DataHolder(data: Data([0xde, 0xad]))
	assertionFailure("❌ Unexpectedly did NOT throw")
} catch {
	print("✅ Got expected error: \(String(describing: error))")
}

@DataStorage(named: "key", byteCount: 32)
public struct PublicKey {}
