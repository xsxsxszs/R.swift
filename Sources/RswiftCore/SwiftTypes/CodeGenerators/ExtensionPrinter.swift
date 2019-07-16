//
//  ExtensionPrinter.swift
//  Commander
//
//  Created by jimmy.chen on 2019/7/11.
//

import Foundation

struct ExtensionPrinter: SwiftCodeConverible, ObjcCodeConvertible {
    
    let swiftCode = [
        "extension R.string {",
        "    static func string(for key: String) -> String {",
        "        return NSLocalizedString(key, tableName: \"Localizable\", bundle: R.hostingBundle, comment: \"\")",
        "    }",
        "}"
        ].joined(separator: "\n")
    
    func objcCode(prefix: String) -> String {
        let productModuleName = ProcessInfo().environment["PRODUCT_MODULE_NAME"] ?? ""
        return [
            "extension \(productModuleName)RObjc {",
            "    static func string(for key: String) -> String {",
            "        return R.string.string(for: key)",
            "    }",
            "}"
            ].joined(separator: "\n")
    }
}
