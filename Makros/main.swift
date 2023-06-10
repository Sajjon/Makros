import MakrosLib
import Foundation

let x = 1
let y = 2

// "Stringify" macro turns the expression into a string.
print(#stringify(x + y))

@DataStorage
struct DataHolder {}
