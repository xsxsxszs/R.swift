//
//  RswiftCore.swift
//  R.swift
//
//  Created by Tom Lokhorst on 2017-04-22.
//  From: https://github.com/mac-cain13/R.swift
//  License: MIT License
//

import Foundation
import XcodeEdit

public struct RswiftCore {

  static public func run(_ callInformation: CallInformation) throws {
    do {
      let xcodeproj = try Xcodeproj(url: callInformation.xcodeprojURL)
      let ignoreFile = (try? IgnoreFile(ignoreFileURL: callInformation.rswiftIgnoreURL)) ?? IgnoreFile()

      let resourceURLs = try xcodeproj.resourcePathsForTarget(callInformation.targetName)
        .map { path in path.url(with: callInformation.urlForSourceTreeFolder) }
        .compactMap { $0 }
        .filter { !ignoreFile.matches(url: $0) }

      let resources = Resources(resourceURLs: resourceURLs, fileManager: FileManager.default)

      let generators: [StructGenerator] = [
        ImageStructGenerator(assetFolders: resources.assetFolders, images: resources.images),
        StringsStructGenerator(localizableStrings: resources.localizableStrings),
      ]

      let aggregatedResult = AggregatedStructGenerator(subgenerators: generators)
        .generatedStructs(at: callInformation.accessLevel, prefix: "")

      let (externalStructWithoutProperties, internalStruct) = ValidatedStructGenerator(validationSubject: aggregatedResult)
        .generatedStructs(at: callInformation.accessLevel, prefix: "")

      let externalStruct = externalStructWithoutProperties.addingInternalProperties(forBundleIdentifier: callInformation.bundleIdentifier)

      let codeConvertibles: [SwiftCodeConverible?] = [
          HeaderPrinter(),
          ImportPrinter(
            modules: callInformation.imports,
            extractFrom: [externalStruct, internalStruct],
            exclude: [Module.custom(name: callInformation.productModuleName)]
          ),
          externalStruct,
          internalStruct
        ]
        
        let objcConvertibles: [ObjcCodeConvertible] = [
            ObjcHeaderPrinter(),
            externalStruct,
            ObjcFooterPrinter(),
        ]

      var fileContents = codeConvertibles
        .compactMap { $0?.swiftCode }
        .joined(separator: "\n\n")
        + "\n\n" // Newline at end of file
      
      if callInformation.objcCompat {
        fileContents += objcConvertibles.compactMap { $0.objcCode(prefix: "") }.joined(separator: "\n") + "\n"
      }
    
      if callInformation.unusedImages {
        let allImages =
          resources.images.map { $0.name } +
          resources.assetFolders.flatMap { $0.imageAssets }

        let allUsedImages =
          resources.nibs.flatMap { $0.usedImageIdentifiers } +
          resources.storyboards.flatMap { $0.usedImageIdentifiers }

        let unusedImages = Set(allImages).subtracting(Set(allUsedImages))
        let unusedImageGeneratedNames = unusedImages.map { SwiftIdentifier(name: $0).description }.uniqueAndSorted()

        fileContents += "/* Potentially Unused Images\n"
        fileContents += unusedImageGeneratedNames.joined(separator: "\n")
        fileContents += "\n*/"
      }

      // Write file if we have changes
      let currentFileContents = try? String(contentsOf: callInformation.outputURL, encoding: .utf8)
      if currentFileContents != fileContents  {
        do {
          try fileContents.write(to: callInformation.outputURL, atomically: true, encoding: .utf8)
        } catch {
          fail(error.localizedDescription)
        }
      }

    } catch let error as ResourceParsingError {
      switch error {
      case let .parsingFailed(description):
        fail(description)

      case let .unsupportedExtension(givenExtension, supportedExtensions):
        let joinedSupportedExtensions = supportedExtensions.joined(separator: ", ")
        fail("File extension '\(String(describing: givenExtension))' is not one of the supported extensions: \(joinedSupportedExtensions)")
      }

      exit(EXIT_FAILURE)
    }
  }
}
