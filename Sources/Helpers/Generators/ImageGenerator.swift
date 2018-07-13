//
//  ImageGenerator.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation

private class ImageStruct: CustomStringConvertible {
    let name: String?
    var subStructs: [ImageStruct] = []
    var images: [String] = []

    init(name: String? = nil) {
        self.name = name
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
}

class ImageGenerator: Generator {
    let outputFolder: String

    required init(outputFolder: String) {
        self.outputFolder = outputFolder
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
            "private func _image(named name: String) -> RadonImage {",
            "return NSImage(named: NSImage.Name(name))!".tabbed(1),
            "}",
            "",
            "#else",
            "public typealias RadonImage = UIImage",
            "import UIKit",
            "",
            "private func _image(named name: String) -> RadonImage {",
            "return UIImage(named: name)!".tabbed(1),
            "}",
            "",
            "#endif",
            "",
            "public extension \(Radon.fileName) {",
        ]

        _print(imageStruct: imageStruct, lines: &lines)

        lines.append("}")

        let contents = lines.joined(separator: "\n")
        File(path: "\(outputFolder)/\(Radon.fileName)+\(name).swift").write(contents)
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
            let varName = imageName.camelCased().appendIfFirstCharacterIsNumber(with: "_")
            let uiimage = "_image(named: \"\(imageName)\")"
            lines.append("public static var \(varName): RadonImage { return \(uiimage) }".tabbed(indent + 1))
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
        let structName = folderName.camelCased().appendIfFirstCharacterIsNumber(with: "_")
        let newStruct = ImageStruct(name: structName)
        imageStruct.subStructs.append(newStruct)
        folder.subFolders.forEach { file in
            _parse(folder: file, in: newStruct)
        }

        for file in folder.files {
            guard let ext = file.extension else {
                continue
            }
            if !allowedExtensions.contains(ext) {
                continue
            }
            guard let name = _imageFileName(from: file) else {
                continue
            }
            if _parsedImageNames.contains(name) {
                continue
            }
            _parsedImageNames.append(name)
            newStruct.images.append(name)
        }
    }


    private func _imageFileName(from file: File) -> String? {
        guard let name = file.fileName else {
            return nil
        }
        return name.components(separatedBy: "@").first
    }
}
