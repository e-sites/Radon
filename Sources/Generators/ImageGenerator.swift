//
//  ImageGenerator.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation
import Francium

private class ImageStruct: CustomStringConvertible {
    private let _name: String?
    var subStructs: [ImageStruct] = []
    var superStruct: ImageStruct?
    var images: [String] = []
    
    var name: String? {
        return self._name?.camelCased().appendIfFirstCharacterIsNumber(with: "_")
    }

    init(name: String? = nil) {
        self._name = name
    }

    var hasImages: Bool {
        if images.isEmpty {
            return !subStructs.filter { $0.hasImages }.isEmpty
        }
        return true
    }

    var description: String {
        return "\(name ?? "nil"): \(hasImages), images: \(images), subStructs: \(subStructs)"
    }
    
    var superFolderName: String? {
        var superStruct: ImageStruct? = self
        var subNames: [String] = []
        while superStruct != nil {
            if let name = superStruct?._name {
                subNames.insert(name, at: 0)
            }
            superStruct = superStruct?.superStruct
        }
        subNames.removeFirst()
        if subNames.isEmpty {
            return nil
        }
        return subNames.joined(separator: "")
    }
}

class ImageGenerator: Generator {
    let outputFolder: String
    let removeFolderName: Bool

    required init(outputFolder: String, removeFolderName: Bool = false) {
        self.outputFolder = outputFolder
        self.removeFolderName = removeFolderName
    }

    private var _parsedImageNames: [String] = []

    var allowedExtensions: [String] {
        return ["tiff", "tif", "jpg", "jpeg", "gif", "png", "bmp", "bmpf", "ico", "cur", "xbm", "imageset"]
    }

    var name: String {
        return "images"
    }

    func parse(folder: Folder) {
        let newFolder = Folder(name: name)
        newFolder.files = folder.files
        newFolder.subFolders = folder.subFolders
        let imageStruct = ImageStruct()

        _parse(folder: newFolder, in: imageStruct)
        var lines: [String] = [
            headerLines(fileName: Radon.fileName),
            "#if os(OSX)",
            "public typealias RadonImage = NSImage",
            "import AppKit",
            "",
            "private func _image(named name: String) -> RadonImage? {",
            "return NSImage(named: NSImage.Name(name))".tabbed(1),
            "}",
            "",
            "#else",
            "public typealias RadonImage = UIImage",
            "import UIKit",
            "",
            "private func _image(named name: String) -> RadonImage? {",
            "return UIImage(named: name)".tabbed(1),
            "}",
            "",
            "#endif",
            "",
            "public extension \(Radon.fileName) {",
        ]

        _print(imageStruct: imageStruct, lines: &lines)

        lines.append("}")

        let contents = lines.joined(separator: "\n")
        do {
            let file = File(path: "\(outputFolder)/\(Radon.fileName)+\(name).swift")
            try file.write(string: contents)
        } catch let error {
            Logger.fatalError("\(error)")
        }
    }

    private func _print(imageStruct: ImageStruct, indent: Int = 0, lines: inout [String]) {
        if !imageStruct.hasImages {
            return
        }

        if let name = imageStruct.name {
            let structName = name.camelCased().appendIfFirstCharacterIsNumber(with: "_")
            lines.append("public struct \(structName) {".tabbed(indent))
            lines.append("private init() { }".tabbed(indent + 1))
        }

        for subStruct in imageStruct.subStructs {
            _print(imageStruct: subStruct, indent: indent + 1, lines: &lines)
        }

        for imageName in imageStruct.images {
            var varName = imageName
            if let superFolderName = imageStruct.superFolderName, removeFolderName == true, varName.hasPrefix(superFolderName) {
                varName = String(varName.dropFirst(superFolderName.count))
            }
            varName = varName.camelCased().appendIfFirstCharacterIsNumber(with: "_")
            let uiimage = "_image(named: \"\(imageName)\")"
            lines.append("public static var \(varName): RadonImage? { return \(uiimage) }".tabbed(indent + 1))
        }

        if imageStruct.name != nil {
            lines.append("}".tabbed(indent))
        }
    }
    

    private func _parse(folder: Folder, in imageStruct: ImageStruct) {

        var folderName = folder.name
        if folderName.hasSuffix(".xcassets") {
            folderName = folderName.replacingOccurrences(of: ".xcassets", with: "")
        }
        
        let newStruct = ImageStruct(name: folderName)
        imageStruct.subStructs.append(newStruct)
        newStruct.superStruct = imageStruct
        folder.subFolders.forEach { file in
            _parse(folder: file, in: newStruct)
        }

        for file in folder.files {
            guard allowedExtensions.contains(file.extensionName),
                let name = _imageFileName(from: file),
                !_parsedImageNames.contains(name) else {
                continue
            }
            
            _parsedImageNames.append(name)
            newStruct.images.append(name)
        }
    }


    private func _imageFileName(from file: File) -> String? {
        return file.name.components(separatedBy: "@").first
    }
}
