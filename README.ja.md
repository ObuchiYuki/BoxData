# BoxData

[![Version](https://img.shields.io/cocoapods/v/BoxData.svg?style=flat)](https://cocoapods.org/pods/BoxData) [![License](https://img.shields.io/cocoapods/l/BoxData.svg?style=flat)](https://cocoapods.org/pods/BoxData) [![Platform](https://img.shields.io/cocoapods/p/BoxData.svg?style=flat)](https://cocoapods.org/pods/BoxData)



BoxDataは、軽量のバイト形式のデータシリアル化ライブラリです。Boxを使用すると、`Codable` なデータをJSONやPlistよりも最大で数千倍も軽く圧縮することができ、それらよりも高速に読み書きできます。



## Example

`Person` というデータを作り、そのデータ10万個を保存した時の値です。

| Type  | File Size                             |
| ----- | ------------------------------------- |
| Box   | <font color=red>`155 B !!!!!!`</font> |
| JSON  | `5.8 MB`                              |
| Plist | `5.4 MB`                              |

```swift
// Codableなデータ
struct Person: Codable {
  let name: String 
  let age: UInt8
  let birth:Conutry
  
	struct Conutry: Codable {
    let name: String
    let id: UInt8
  }
}

// データの準備
let alice = Person(name: "Alice", age: 17, birth: .init(name: "UK"     , id: 12))
let bob   = Person(name: "Bob"  , age: 22, birth: .init(name: "America", id: 14))
        
/// 100000 データ
let people = Array(repeating: alice, count: 50000) 
					 + Array(repeating: bob  , count: 50000)
        
```



## 使用方法

 `BoxEncoder` と `BoxDecoder` は `JSONEncoder` や `PropertyListEncoder` などと同様に使えるので、すでにこれらを使っていた場合は、名前以外に変更するとことは一切ありません。

```swift
do {
  // encoding
	let data = try BoxEncoder().encode(people)
  
  // decoding
	let decoded = try BoxDecoder().decode(Array<Person>.self, from: data)
  
} catch {
	print(error)
}
```

実際にDemoを動かすにはこのレポジトリを`Clone`して、`pod install`し実行してください。

#### オプション

`BoxEncoder`には 2つのOptionがあります。

- `useStructureCache`

  構造キャッシュを使用するかどうかです。多くの場合、数倍の容量削減になります。

- `compressionLevel`

	圧縮レベルです。`0`から`6`まで設定できます。

```swift
let encoder = BoxEncoder()

// エンコード前に設定してください。
encoder.useStructureCache = true / false
encoder.compressionLevel = 0...6
```



## インストール

 [CocoaPods](https://cocoapods.org) 経由でのインストールが可能です。インストールにはPodfileに以下を追加してください。

```ruby
pod 'BoxData'
```



## 著者

大渕雄生, yukibochi1@gmail.com



## License

BoxData is available under the MIT license. See the LICENSE file for more info.
