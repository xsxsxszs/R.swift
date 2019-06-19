//
//  Type.swift
//  R.swift
//
//  Created by Mathijs Kadijk on 10-12-15.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation

struct UsedType {
  let type: Type

  fileprivate init(type: Type) {
    self.type = type
  }
}

struct Type: UsedTypesProvider, CustomStringConvertible, Hashable {
  static let _Void = Type(module: .stdLib, name: "Void")
  static let _Any = Type(module: .stdLib, name: "Any")
  static let _AnyObject = Type(module: .stdLib, name: "AnyObject")
  static let _String = Type(module: .stdLib, name: "String")
  static let _Int = Type(module: .stdLib, name: "Int")
  static let _UInt = Type(module: .stdLib, name: "UInt")
  static let _Double = Type(module: .stdLib, name: "Double")
  static let _Character = Type(module: .stdLib, name: "Character")
  static let _CStringPointer = Type(module: .stdLib, name: "UnsafePointer<unichar>")
  static let _VoidPointer = Type(module: .stdLib, name: "UnsafePointer<Void>")
  static let _URL = Type(module: "Foundation", name: "URL")
  static let _Bundle = Type(module: "Foundation", name: "Bundle")
  static let _Locale = Type(module: "Foundation", name: "Locale")
  static let _UINib = Type(module: "UIKit", name: "UINib")
  static let _UIView = Type(module: "UIKit", name: "UIView")
  static let _UIImage = Type(module: "UIKit", name: "UIImage")
  static let _UIStoryboard = Type(module: "UIKit", name: "UIStoryboard")
  static let _UITableViewCell = Type(module: "UIKit", name: "UITableViewCell")
  static let _UICollectionViewCell = Type(module: "UIKit", name: "UICollectionViewCell")
  static let _UICollectionReusableView = Type(module: "UIKit", name: "UICollectionReusableView")
  static let _UIStoryboardSegue = Type(module: "UIKit", name: "UIStoryboardSegue")
  static let _UITraitCollection = Type(module: "UIKit", name: "UITraitCollection")
  static let _UIViewController = Type(module: "UIKit", name: "UIViewController")
  static let _UIFont = Type(module: "UIKit", name: "UIFont")
  static let _UIColor = Type(module: "UIKit", name: "UIColor")
  static let _CGFloat = Type(module: .stdLib, name: "CGFloat")
  static let _CVarArgType = Type(module: .stdLib, name: "CVarArgType...")

  static let ReuseIdentifier = Type(module: "PDFoundation", name: "ReuseIdentifier", genericArgs: [TypeVar(description: "T", usedTypes: [])])
  static let ReuseIdentifierType = Type(module: "PDFoundation", name: "ReuseIdentifierType")
  static let StoryboardResourceType = Type(module: "PDFoundation", name: "StoryboardResourceType")
  static let StoryboardResourceWithInitialControllerType = Type(module: "PDFoundation", name: "StoryboardResourceWithInitialControllerType")
  static let StoryboardViewControllerResource = Type(module: "PDFoundation", name: "StoryboardViewControllerResource")
  static let NibResourceType = Type(module: "PDFoundation", name: "NibResourceType")
  static let FileResource = Type(module: "PDFoundation", name: "FileResource")
  static let FontResource = Type(module: "PDFoundation", name: "FontResource")
  static let ColorResource = Type(module: "PDFoundation", name: "ColorResource")
  static let ImageResource = Type(module: "PDFoundation", name: "ImageResource")
  static let StringResource = Type(module: "PDFoundation", name: "StringResource")
  static let Strings = Type(module: "PDFoundation", name: "Strings")
  static let Validatable = Type(module: "PDFoundation", name: "Validatable")
  static let TypedStoryboardSegueInfo = Type(module: "PDFoundation", name: "TypedStoryboardSegueInfo", genericArgs: [TypeVar(description: "Segue", usedTypes: []), TypeVar(description: "Source", usedTypes: []), TypeVar(description: "Destination", usedTypes: [])])

  let module: Module
  let name: SwiftIdentifier
  let genericArgs: [TypeVar]
  let optional: Bool

  var usedTypes: [UsedType] {
    return [UsedType(type: self)] + genericArgs.flatMap(getUsedTypes)
  }

  var description: String {
    return TypePrinter(type: self).swiftCode
  }

  var hashValue: Int {
    return description.hashValue
  }

  init(module: Module, name: SwiftIdentifier, genericArgs: [TypeVar] = [], optional: Bool = false) {
    self.module = module
    self.name = name
    self.genericArgs = genericArgs
    self.optional = optional
  }

  init(module: Module, name: SwiftIdentifier, genericArgs: [Type], optional: Bool = false) {
    self.module = module
    self.name = name
    self.genericArgs = genericArgs.map(TypeVar.init)
    self.optional = optional
  }

  func asOptional() -> Type {
    return Type(module: module, name: name, genericArgs: genericArgs, optional: true)
  }

  func asNonOptional() -> Type {
    return Type(module: module, name: name, genericArgs: genericArgs, optional: false)
  }

  func withGenericArgs(_ genericArgs: [TypeVar]) -> Type {
    return Type(module: module, name: name, genericArgs: genericArgs, optional: optional)
  }

  func withGenericArgs(_ genericArgs: [Type]) -> Type {
    return Type(module: module, name: name, genericArgs: genericArgs, optional: optional)
  }
}

func ==(lhs: Type, rhs: Type) -> Bool {
  return (lhs.hashValue == rhs.hashValue)
}
