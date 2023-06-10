# `@DataStorage`

Makes it easy to work with `Data`.

## No args
```swift
@DataStorage
struct DataHolder {}
```

Expands to:
```swift
struct DataHolder {
	let data: Data
	
	init(data: Data) {
		self.data = data
	}
}
```

## `byteCount`

```swift
@DataStorage(named: "key", byteCount: 32)
public struct PublicKey {}
```

Expands to:

```swift
public struct PublicKey {
	public let key: Data
	
	public static let byteCount = 32
	struct InvalidByteCount: Swift.Error, CustomStringConvertible {
		let actual: Int
		var description: String {
			" Invalid byteCount, expected: \(PublicKey.byteCount) , but got: 	\(actual) "
		}
	}
	
	public init(key: Data) throws {
		guard key.count == Self.byteCount else {
			throw InvalidByteCount(actual: key.count)
		}
		self.key = key
	}
}
```
