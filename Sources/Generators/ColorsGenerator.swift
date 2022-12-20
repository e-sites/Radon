//
//  ColorsGenerator.swift
//  Radon
//
//  Created by Bas van Kuijck on 10/10/2022.
//

import Foundation
import Francium

class ColorStruct: ObjStruct {
    var path: String = ""
}

class ColorsGenerator: Generator {
    
    let config: Config

    required init(config: Config) {
        self.config = config
    }
    
    private var _parsedNames: [String] = []

    var allowedExtensions: [String] {
        return ["colorset"]
    }

    var name: String {
        return "colors"
    }

    func parse(folder: Folder) {
        let newFolder = Folder(name: name)
        newFolder.files = folder.files
        newFolder.subFolders = folder.subFolders
        let objStruct = ColorStruct()

        _parse(folder: newFolder, in: objStruct)
        var lines: [String] = [
            headerLines(fileName: Radon.fileName),
            "#if os(OSX)",
            "public typealias RadonColor = NSColor",
            "import AppKit",
            "#else",
            "public typealias RadonColor = UIColor",
            "import UIKit",
            "#endif",
            "",
            "private func color(named name: String) -> RadonColor {",
            "return RadonColor(named: name, in: \(config.bundleName), compatibleWith: nil)!".tabbed(1),
            "}",
            "",
            "extension \(Radon.fileName) {",
        ]
        
        _print(objStruct: objStruct, lines: &lines)

        lines.append("}")

        let contents = lines.joined(separator: "\n")
        do {
            let file = File(path: "\(config.outputFolder)/\(Radon.fileName)+\(name).swift")
            try file.write(string: contents)
        } catch let error {
            Logger.fatalError("\(error)")
        }
    }

    private func _print(objStruct: ColorStruct, indent: Int = -1, lines: inout [String]) {
        if !objStruct.hasObjects {
            return
        }

        if let name = objStruct.name, indent > 0 {
            let structName = name.camelCased().appendIfFirstCharacterIsNumber(with: "_")
            lines.append("public enum \(structName.predefinedString) {".tabbed(indent))
        }

        for subStruct in objStruct.subStructs {
            _print(objStruct: subStruct as! ColorStruct, indent: indent + 1, lines: &lines)
        }
        
        for objName in objStruct.objects {
            var varName = objName
            if let superFolderName = objStruct.superFolderName, config.removeFolderName, varName.hasPrefix(superFolderName) {
                varName = String(varName.dropFirst(superFolderName.count))
            }
            varName = varName.camelCased().appendIfFirstCharacterIsNumber(with: "_")
            lines.append("public static var \(varName.predefinedString): RadonColor { return color(named: \"\(objName)\") }".tabbed(indent + 1))
        }

        if objStruct.name != nil, indent > 0 {
            lines.append("}".tabbed(indent))
        }
    }
    

    private func _parse(folder: Folder, in objStruct: ColorStruct, first: Bool = false) {
        var folderName = folder.name
        if folderName == "Assets" && config.stripXCAssets && objStruct.name == name {
            folder.subFolders.forEach { file in
                _parse(folder: file, in: objStruct, first: true)
            }
            return
        }
        if folderName.hasSuffix(".xcassets") {
            folderName = folderName.replacingOccurrences(of: ".xcassets", with: "")
        }
        
        let newStruct = ColorStruct(name: folderName)
        objStruct.subStructs.append(newStruct)
        newStruct.superStruct = objStruct
        folder.subFolders.forEach { file in
            _parse(folder: file, in: newStruct)
        }

        for file in folder.files {
            guard allowedExtensions.contains(file.extensionName),
                  !_parsedNames.contains(file.name)
            else {
                continue
            }
            _parsedNames.append(file.name)
            newStruct.objects.append(file.name)
        }
    }
}
