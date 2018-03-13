
<p align="center">
  <!-- <img src="./Assets/Oath.png" alt="Oath"> -->
  <br/><a href="https://cocoapods.org/pods/Oath">
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.0-brightgreen.svg">
  <img alt="Author" src="https://img.shields.io/badge/author-Meniny-blue.svg">
  <img alt="Build Passing" src="https://img.shields.io/badge/build-passing-brightgreen.svg">
  <img alt="Swift" src="https://img.shields.io/badge/swift-4.0%2B-orange.svg">
  <br/>
  <img alt="Platforms" src="https://img.shields.io/badge/platform-macOS%20%7C%20iOS%20%7C%20tvOS-lightgrey.svg">
  <img alt="MIT" src="https://img.shields.io/badge/license-MIT-blue.svg">
  <br/>
  <img alt="Cocoapods" src="https://img.shields.io/badge/cocoapods-compatible-brightgreen.svg">
  <img alt="Carthage" src="https://img.shields.io/badge/carthage-working%20on-red.svg">
  <img alt="SPM" src="https://img.shields.io/badge/swift%20package%20manager-compatible-brightgreen.svg">
  </a>
</p>

## 🏵 Introduction

**Oath** is a `Promise` / `Future` concept implementation for Swift developing.

Learn [more](https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Promise) about `Promise`.

## 📋 Requirements

- iOS 8.0+
- macOS 10.10+
- tvOS 9.0+
- Xcode 9.0+ with Swift 4.0+

## 📲 Installation

`Oath` is available on [CocoaPods](https://cocoapods.org):

```ruby
use_frameworks!
pod 'Oath'
```

## ❤️ Contribution

You are welcome to fork and submit pull requests.

## 🔖 License

`Oath` is open-sourced software, licensed under the `MIT` license.

## 💫 Usage

```swift
fetchUserInfo().then { info in
    print("User: \(info)")
}.onError { e in
    print("An error occured : \(e)")
}.finally {
    print("Everything is done <3")
}
```

```swift
func fetchUserInfo() -> Promise<String> {
    return Promise { resolve, reject in
        print("fetching user info...")
        wait { resolve("Elias") }
    }
}
```
