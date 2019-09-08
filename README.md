# Box Data
`BoxData` は iOS アプリで多少大きなデータを保存するのに最適なバイトコードフォーマットです。
`JSON`と比べて高速に読み書きが行え、ファイルサイズも非常に小さくなります。

標準の `JsonEncoder` ・`JsonDecoder`と同様に使える、`BoxEncoder`・`BoxDecoder` を使えば、非常に簡単に使用できます。



## Usage



##### `Codable Class`

```swift
struct Person: Codable {
  let name:String
  let age:Int							
  let itemIds:[UInt16]			// allow array
  let birth:Country					// allow nest
  let birthDay: Date				// allow Date

  struct Country: Codable {
		let name:String					
    let state:String?				// allow nil
  }
}

let alice = Person(
  name: "Alice", age: 16, itemIds: [12, 4],
  data: Date(...)
  birth: .init(name: "UK", state: nil)
)

let encoder = BoxEncoder()
let data = try encoder.encode(alice)

let decoder = BoxDecoder()
let decodedAlice = try decoder.decode(Person.self, from: data)

// decodedAlice is alice!!
```



##### `SingleValue`

単一の値を保存することもできます。

```swift
let encoder = BoxEncoder()
let data = try encoder.encode(true)

let decoder = BoxDecoder()
let decoded = try decoder.decode(Bool.self, from: data)

print(decoded) // true
```



