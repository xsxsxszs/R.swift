//
//  UnusedImages.swift
//  RswiftCore
//
//  Created by Brian Clymer on 5/26/19.
//

import Foundation
import XcodeEdit

class UnusedImages {
    
    static func identifyUnusedImages(xcodeproj: Xcodeproj, resources: Resources, callInformation: CallInformation) throws -> String {
        let allImages =
            resources.images.map { $0.name } +
            resources.assetFolders.flatMap { $0.imageAssets }
        
        let allUsedImages =
            resources.nibs.flatMap { $0.usedImageIdentifiers } +
            resources.storyboards.flatMap { $0.usedImageIdentifiers }
        
        let unusedImages = Set(allImages).subtracting(Set(allUsedImages))
        let threadSafeUnusedImages = ThreadSafeSet(Set(unusedImages.map { PotentiallyUnusedImage(originalName: $0) }))
        
        let sourceFiles = try xcodeproj.sourceFiles(callInformation.targetName)
            .compactMap { path in path.url(with: callInformation.urlForSourceTreeFolder) }
        
        let swiftFiles = sourceFiles.filter { $0.pathExtension == "swift" && $0.filename != "R.generated" }
        let objcFiles = sourceFiles.filter { $0.pathExtension == "m" }
        
        let cores = ProcessInfo.processInfo.activeProcessorCount
        let swiftChunks = swiftFiles.chunked(into: (swiftFiles.count / cores) + 1)
        DispatchQueue.concurrentPerform(iterations: cores) { (index) in
            swiftChunks[index].forEach { url in
                guard let contents = try? String(contentsOf: url), contents.contains("R.image.") else { return }
                let local = threadSafeUnusedImages.backingSet
                let found = local.filter { image -> Bool in
                    return contents.contains(image.swiftName)
                }
                if !found.isEmpty {
                    threadSafeUnusedImages.subtract(found)
                }
            }
        }
        
        let objcChunks = objcFiles.chunked(into: (swiftFiles.count / cores) + 1)
        DispatchQueue.concurrentPerform(iterations: cores) { (index) in
            objcChunks[index].forEach {
                guard let contents = try? String(contentsOf: $0), contents.contains("[RObjc image_") else { return }
                let local = threadSafeUnusedImages.backingSet
                let found = local.filter { image -> Bool in
                    return contents.contains(image.objcName)
                }
                if !found.isEmpty {
                    threadSafeUnusedImages.subtract(found)
                }
            }
        }
        
        let unusedImageGeneratedNames = Array(threadSafeUnusedImages.backingSet).map { $0.originalName }.sorted()
        
        var fileContents = "/* Potentially Unused Images\n"
        fileContents += unusedImageGeneratedNames.joined(separator: "\n")
        fileContents += "\n*/"
        
        return fileContents
    }
    
}


private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

private class ThreadSafeSet<Element> where Element : Hashable {
    private let lock = NSRecursiveLock()
    var backingSet: Set<Element>
    
    init(_ set: Set<Element>) {
        backingSet = set
    }
    
    func subtract(_ other: Set<Element>) {
        lock.lock()
        backingSet.subtract(other)
        lock.unlock()
    }
}

private struct PotentiallyUnusedImage: Hashable {
    let swiftName: String
    let objcName: String
    let originalName: String
    
    init(originalName: String) {
        self.originalName = originalName
        let swiftId = SwiftIdentifier(name: originalName).description
        self.swiftName = "R.image.\(swiftId)"
        self.objcName = "[RObjc image_\(swiftId)]"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(originalName)
    }
}
