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
    let value: String
    let isPlural: Bool
    
    init(key: String, value: String = "", isPlural: Bool = false) {
        self.key = key
        self.value = value
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
    
    private var localizationFolders: [String] = []
    private var locales: [String: LocaleObject] = [:]
    
    let config: Config
    
    required init(config: Config) {
        self.config = config
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
            "",
            "public enum \(name) {".tabbed(1)
        ]
        iterate(obj: baseObj, lines: &lines)
        lines.append("}".tabbed(1))
        lines.append("}")
        
        let contents = lines.joined(separator: "\n")
        //        print(contents)
        do {
            let file = File(path: "\(config.outputFolder)/\(Radon.fileName)+\(name).swift")
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
        
        return Array(dictionary.keys).map { key in
            var value: String?
            if let dic = dictionary[key] as? [String: Any],
               let translations = Array(dic.keys).compactMap({ dic[$0] as? [String: Any] }).first as? [String: String] {
                value = translations["other"] ?? translations["one"]
            }
            return StringKey(key: key, value: value ?? "", isPlural: true)
        }
    }
    
    private func iterate(obj: LocaleObject, indent: Int = 2, lines: inout [String]) {
        if obj.subs.count == 1, let sub = obj.subs.first, !sub.key.key.isEmpty {
            lines.append(createStaticVar(sub, indent: indent))
            
        } else {
            for sub in obj.subs {
                if sub.subs.isEmpty {
                    lines.append(createStaticVar(sub, indent: indent))
                } else {
                    lines.append("public enum \(sub.name.predefinedString) {".tabbed(indent))
                    iterate(obj: sub, indent: indent + 1, lines: &lines)
                    lines.append("}".tabbed(indent))
                }
            }
        }
    }
    
    private func createStaticVar(_ sub: LocaleObject, indent: Int) -> String {
        if sub.key.isPlural {
            return "/// Plural '\(sub.key.value)'\n".tabbed(indent) +
            "public static func \(sub.name.predefinedString)(_ count: Int, locale: Locale = Radon.defaultPluralLocale) -> String { String(format: NSLocalizedString(\"\(sub.key.key)\", bundle: \(config.bundleName), comment: \"\"), locale: locale, count) }\n".tabbed(indent)
        }
        
        return "/// '\(sub.key.value)'\n".tabbed(indent) +
        "public static var \(sub.name.predefinedString): String { NSLocalizedString(\"\(sub.key.key)\", bundle: \(config.bundleName), comment: \"\") }\n".tabbed(indent)
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
        
        if config.fullLocalizationKeys {
            let name = removePlaceholder(
                key.key
                    .lowercased()
                    .appendIfFirstCharacterIsNumber(with: "_")
            )
                .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "0123456789_")).inverted)
                .joined()
            
            let obj = LocaleObject(name: name)
            obj.key = key
            parent.subs.append(obj)
            return parent
        }
        
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
        var keys: [(String, String)] = []
        let lines = contents.components(separatedBy: "\n")
        for line in lines {
            do {
                let regex = try NSRegularExpression(pattern: #""(.+?)"(| )=(| )"(.+?)";"#)
                let results = regex.matches(in: line, range: NSRange(location: 0, length: line.count))
                for result in results where result.numberOfRanges == 5 {
                    keys.append(
                        (
                            NSString(string: line).substring(with: result.range(at: 1)),
                            NSString(string: line).substring(with: result.range(at: 4))
                        )
                    )
                }
            } catch {
            }
        }
        return keys.map { StringKey(key: $0.0, value: $0.1) }
    }
}
