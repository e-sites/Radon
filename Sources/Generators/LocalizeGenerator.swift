//
//  LocalizeGenerator.swift
//  
//
//  Created by Bas van Kuijck on 08/06/2022.
//

import Foundation
import Francium

private class LocaleObject: CustomDebugStringConvertible {
    var subs: [LocaleObject] = []
    let name: String

    var key: StringKey = StringKey(key: "")
    
    init(name: String = "") {
        self.name = name
    }

    var debugDescription: String {
        return "<'\(name)': key: '\(key)', subs: \(subs)>"
    }
}

struct StringKey: Hashable {
    let key: String
    let isPlural: Bool
    
    init(key: String, isPlural: Bool = false) {
        self.key = key
        self.isPlural = isPlural
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    
    static func == (lhs: StringKey, rhs: StringKey) -> Bool {
        return lhs.key == rhs.key
    }
}

class LocalizeGenerator: Generator {
    var name: String {
        return "strings"
    }
    
    var allowedExtensions: [String] {
        return [ "lproj" ]
    }
    
    let outputFolder: String
    let removeFolderName: Bool
    private var localizationFolders: [String] = []
    private var locales: [String: LocaleObject] = [:]
    
    required init(outputFolder: String, removeFolderName: Bool = false) {
        self.outputFolder = outputFolder
        self.removeFolderName = removeFolderName
    }
    
    func parse(folder: Folder) {
        _parse(folder: folder)
        var allKeys: [StringKey] = []
        
        for folderPath in localizationFolders {
            let dir = Dir(path: folderPath)
            let files = dir.glob("*.strings*")
            for file in files {
                if file.extensionName == "strings", let contents = file.contents {
                    allKeys.append(contentsOf: parse(contents: contents))
                } else if file.extensionName == "stringsdict"{
                    allKeys.append(contentsOf: parseStringsDict(file: file))
                }
            }
        }
        
        let baseObj = LocaleObject()
        for key in allKeys.unique().sorted(by: { $0.key < $1.key }) {
            iterate(key: key, parent: baseObj).key = key
        }
        
        var lines: [String] = [
            headerLines(fileName: Radon.fileName),
            "import Foundation",
            "",
            "extension \(Radon.fileName) {",
            "enum \(name) {".tabbed(1)
        ]
        iterate(obj: baseObj, lines: &lines)
        lines.append("}".tabbed(1))
        lines.append("}")
        
        let contents = lines.joined(separator: "\n")
//        print(contents)
        do {
            let file = File(path: "\(outputFolder)/\(Radon.fileName)+\(name).swift")
            try file.write(string: contents)
        } catch let error {
            Logger.fatalError("\(error)")
        }
    }
    
    private func parseStringsDict(file: File) -> [StringKey] {
        let url = URL(fileURLWithPath: file.absolutePath)
        guard let dictionary = NSDictionary(contentsOf: url) as? Dictionary<String, Any> else {
            return []
        }
        
        return Array(dictionary.keys).map { StringKey(key: $0, isPlural: true) }
    }
    
    private func iterate(obj: LocaleObject, indent: Int = 2, lines: inout [String]) {
        if obj.subs.count == 1, let sub = obj.subs.first, !sub.key.key.isEmpty {
            lines.append(createStaticVar(sub).tabbed(indent))
            
        } else {
            for sub in obj.subs {
                if sub.subs.isEmpty {
                    lines.append(createStaticVar(sub).tabbed(indent))
                } else {
                    lines.append("enum \(sub.name.predefinedString) {".tabbed(indent))
                    iterate(obj: sub, indent: indent + 1, lines: &lines)
                    lines.append("}".tabbed(indent))
                }
            }
        }
    }
    
    private func createStaticVar(_ sub: LocaleObject) -> String {
        if sub.key.isPlural {
            return "static func \(sub.name.predefinedString)(_ count: Int) -> String { String(format: NSLocalizedString(\"\(sub.key.key)\", comment: \"\"), count) }"
        }
        
        return "static var \(sub.name.predefinedString): String { NSLocalizedString(\"\(sub.key.key)\", comment: \"\") }"
    }
    
    private func removePlaceholder(_ string: String) -> String {
        var string = string
        let modifiers = [ "", "h", "hh", "l", "ll", "q", "L", "z", "t", "j", ".01", ".02", ".03", ".04", ".05", ".06" ]
        for char in [ "d", "@", "%", "lld", "u", "x", "o", "O", "f", "e", "E", "g", "G", "c", "C", "s", "S", "p", "a", "A", "F" ] {
            for modifier in modifiers {
                string = string.replacingOccurrences(of: "%\(modifier)\(char)", with: "")
            }
        }
        return string
    }

    
    private func iterate(key: StringKey, parent: LocaleObject) -> LocaleObject {
        var parent = parent
        for spl in key.key.components(separatedBy: "_") {
            let name = removePlaceholder(
                spl
                    .lowercased()
                    .appendIfFirstCharacterIsNumber(with: "_")
            )
                .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "0123456789_")).inverted)
                .joined()
            
            if let obj = parent.subs.first(where: { $0.name == name }) {
                parent = obj
            } else {
                if parent.key.key.isEmpty {
                    let obj = LocaleObject(name: name)
                    parent.subs.append(obj)
                    parent = obj
                } else {
                    let replaceObj = LocaleObject(name: "value")
                    replaceObj.key = parent.key
                    parent.key = StringKey(key: "")
                    parent.subs.append(replaceObj)
                    
                    let obj = LocaleObject(name: name)
                    parent.subs.append(obj)
                    parent = obj
                }
            }
        }
        return parent
    }
    
    private func _parse(folder: Folder) {
        for subFolder in folder.subFolders {
            _parse(folder: subFolder)
        }
        for file in folder.files {
            if file.dirName.hasSuffix(".lproj"), !localizationFolders.contains(file.dirName) {
                localizationFolders.append(file.dirName)
            }
        }
    }
    
    private func parse(contents: String) -> [StringKey] {
        var keys: [String] = []
        let lines = contents.components(separatedBy: "\n")
        for line in lines {
            do {
                let regex = try NSRegularExpression(pattern: #""(.+?)"(| )=(| )"(.+?)";"#)
                let results = regex.matches(in: line, range: NSRange(location: 0, length: line.count))
                for result in results where result.numberOfRanges == 5 {
                    keys.append(NSString(string: line).substring(with: result.range(at: 1)))
                }
            } catch {
            }
        }
        return keys.map { StringKey(key: $0) }
    }
}
