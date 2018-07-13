//
//  ImageGenerator.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation

class ImageGenerator: Generator {
    let outputFolder: String

    required init(outputFolder: String) {
        self.outputFolder = outputFolder
    }

    private var _lines: [String] = []
    private var _parsedImageNames: [String] = []

    var allowedExtensions: [String] {
        return ["tiff", "tif", "jpg", "jpeg", "gif", "png", "bmp", "bmpf", "ico", "cur", "xbm", "imageset"]
    }

    var name: String {
        return "images"
    }

    func parse(folder: Folder) {
        folder.name = name
        _lines = [
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
        _parse(folder: folder, indent: 1)
        _lines.append("}")
        let contents = _lines.joined(separator: "\n")
        File(path: "\(outputFolder)/\(Radon.fileName)+\(name).swift").write(contents)
    }

    private func _parse(folder: Folder, indent: Int) {

        var folderName = folder.name
        if folderName.hasSuffix(".xcassets") {
            folderName = folderName.replacingOccurrences(of: ".xcassets", with: "")
        }
        let className = folderName.camelCased().appendIfFirstCharacterIsNumber(with: "_")
        _lines.append("public struct \(className) {".tabbed(indent))
        _lines.append("private init() { }\n".tabbed(indent + 1))
        folder.subFolders.forEach {
            _parse(folder: $0, indent: indent + 1)
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
            let varName = name.camelCased().appendIfFirstCharacterIsNumber(with: "_")
            let uiimage = "_image(named: \"\(name)\")"
            _lines.append("public static var \(varName): RadonImage { return \(uiimage) }".tabbed(indent + 1))
        }
        _lines.append("}\n".tabbed(indent))
    }


    private func _imageFileName(from file: File) -> String? {
        guard let name = file.fileName else {
            return nil
        }
        return name.components(separatedBy: "@").first
    }
}
