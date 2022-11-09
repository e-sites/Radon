//
//  ImageGenerator.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation
import Francium

class ImageGenerator: Generator {
    let config: Config

    required init(config: Config) {
        self.config = config
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
        let imageStruct = ObjStruct()

        _parse(folder: newFolder, in: imageStruct)
        var lines: [String] = [
            headerLines(fileName: Radon.fileName),
            "#if os(OSX)",
            "public typealias RadonImage = NSImage",
            "import AppKit",
            "#else",
            "public typealias RadonImage = UIImage",
            "import UIKit",
            "#endif",
            "",
            "private func image(named name: String) -> RadonImage? {",
            "#if os(OSX)",
            "return NSImage(named: NSImage.Name(name))".tabbed(1),
            "#else",
            "return UIImage(named: name, in: \(config.bundleName), compatibleWith: nil)".tabbed(1),
            "#endif",
            "}",
            "",
            "extension \(Radon.fileName) {",
        ]

        _print(imageStruct: imageStruct, lines: &lines)

        lines.append("}")

        let contents = lines.joined(separator: "\n")
        do {
            let file = File(path: "\(config.outputFolder)/\(Radon.fileName)+\(name).swift")
            try file.write(string: contents)
        } catch let error {
            Logger.fatalError("\(error)")
        }
    }

    private func _print(imageStruct: ObjStruct, indent: Int = 0, lines: inout [String]) {
        if !imageStruct.hasObjects {
            return
        }

        if let name = imageStruct.name {
            let structName = name.camelCased().appendIfFirstCharacterIsNumber(with: "_")
            lines.append("public enum \(structName.predefinedString) {".tabbed(indent))
        }

        for subStruct in imageStruct.subStructs {
            _print(imageStruct: subStruct, indent: indent + 1, lines: &lines)
        }

        for imageName in imageStruct.objects {
            var varName = imageName
            if let superFolderName = imageStruct.superFolderName, config.removeFolderName, varName.hasPrefix(superFolderName) {
                varName = String(varName.dropFirst(superFolderName.count))
            }
            varName = varName.camelCased().appendIfFirstCharacterIsNumber(with: "_")
            let uiimage = "image(named: \"\(imageName)\")"
            lines.append("public static var \(varName.predefinedString): RadonImage? { return \(uiimage) }".tabbed(indent + 1))
        }

        if imageStruct.name != nil {
            lines.append("}".tabbed(indent))
        }
    }
    

    private func _parse(folder: Folder, in imageStruct: ObjStruct) {
        var folderName = folder.name
        if folderName == "Assets" && config.stripXCAssets && imageStruct.superStruct?.name == nil {
            folder.subFolders.forEach { file in
                _parse(folder: file, in: imageStruct)
            }
            return
            
        }
        if folderName.hasSuffix(".xcassets") {
            folderName = folderName.replacingOccurrences(of: ".xcassets", with: "")
        }
        
        let newStruct = ObjStruct(name: folderName)
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
            newStruct.objects.append(name)
        }
    }


    private func _imageFileName(from file: File) -> String? {
        return file.name.components(separatedBy: "@").first
    }
}
