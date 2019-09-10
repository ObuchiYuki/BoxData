# BoxData

[![Version](https://img.shields.io/cocoapods/v/BoxData.svg?style=flat)](https://cocoapods.org/pods/BoxData)[![License](https://img.shields.io/cocoapods/l/BoxData.svg?style=flat)](https://cocoapods.org/pods/BoxData)[![Platform](https://img.shields.io/cocoapods/p/BoxData.svg?style=flat)](https://cocoapods.org/pods/BoxData)



BoxData is a lightweight byte format data serialization library. With Box, you can compress `Codable` data up thousands of times lighter than JSON or Plist, and can read and write faster than those.

You can use `BoxEncoder` and `BoxDecoder` like `JSONEncoder` or `PropertyListEncoder`.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```swift
import BoxData

// Codable Data
struct Person: Codable {
  let name: String 
  let age: UInt8
  let birth:Conutry
  
	struct Conutry: Codable {
    let name: String
    let id: UInt8
  }
}

// Data
let alice = 


let encoder = BoxEncoder()
let decoder = BoxDecoder()


```





## Installation

BoxData is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BoxData'
```

## Author

ObuchiYuki, yukibochi1@gmail.com

## License

BoxData is available under the MIT license. See the LICENSE file for more info.
