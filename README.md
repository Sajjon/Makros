# `@DataStorage`

```swift
@DataStorage
struct DataHolder {}

assert(DataHolder(data: Data([0xde, 0xad, 0xbe, 0xef])).data.count == 4)
```