//
//  String.swift
//  CommandLineKit
//
//  Created by Bas van Kuijck on 20/10/2017.
//

import Foundation
import Cryptor

infix operator =~

/**
 Regular expression match
 
 let match = ("ABC123" =~ "[A-Z]{3}[0-9]{3}") // true
 */
func =~ (string: String, regex: String) -> Bool {
    return string.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
}

extension String {
    func capturedGroups(withRegex pattern: String,
                        options: NSRegularExpression.Options = []) -> [(Range<String.Index>, String)] {
        var results: [(Range<String.Index>, String)] = []
        
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            return results
        }
        
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
        
        guard let match = matches.first else {
            return results
        }
        
        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else {
            return results
        }
        
        for index in 1...lastRangeIndex {
            let capturedGroupIndex = match.range(at: index)
            
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            if let range = Range(capturedGroupIndex, in: self) {
                results.append((range, matchedString))
            }
        }
        
        return results
    }

    var md5: [UInt8] {
        let md5 = Digest(using: .md5)
        _ = md5.update(string: self)
        return md5.final()
    }


    func uncapitalizeFirstLetter() -> String {
        return prefix(1).lowercased() + dropFirst()
    }

    func appendIfFirstCharacterIsNumber(with string: String = "") -> String {
        if let firstChar = self.first, let _ = Int("\(firstChar)") {
            return "\(string)\(self)"
        }
        return self
    }

    func tabbed(_ count: Int = 0) -> String {
        let spacing = "    "
        var tab = ""
        for _ in 0..<count {
            tab += spacing
        }
        return "\(tab)\(self)"
    }
}


import Foundation

public enum StringCaseFormat {

    public enum CamelCase {
        case `default`
        case capitalized
    }
}

public extension String {

    public func caseSplit() -> [String] {
        var res: [String] = []
        let trim = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let alphanumerics = CharacterSet.alphanumerics
        let uppercaseLetters = CharacterSet.uppercaseLetters
        let lowercaseLetters = CharacterSet.lowercaseLetters
        trim.split(separator: " ").forEach { str in
            var previousCase = 0
            var currentCase = 0
            var caseChange = false
            var scalars = UnicodeScalarView()
            for scalar in str.unicodeScalars {
                if alphanumerics.contains(scalar) {
                    if uppercaseLetters.contains(scalar) {
                        currentCase = 1
                    } else if lowercaseLetters.contains(scalar) {
                        currentCase = 2
                    } else {
                        currentCase = 0
                    }
                    let letterInWord = scalars.count
                    if !caseChange && letterInWord > 0 {
                        if currentCase != previousCase {
                            if previousCase == 1 {
                                if letterInWord > 1 {
                                    caseChange = true
                                }
                            } else {
                                caseChange = true
                            }
                        }
                    }
                    if caseChange {
                        res.append(String(scalars))
                        scalars.removeAll()
                    }
                    scalars.append(scalar)
                    caseChange = false
                    previousCase = currentCase
                } else {
                    caseChange = true
                }
            }
            if scalars.count > 0 {
                res.append(String(scalars))
            }
        }
        return res
    }

    public func camelCased(_ format: StringCaseFormat.CamelCase = .default) -> String {
        var res: [String] = []
        for (i, str) in self.caseSplit().enumerated() {
            if i == 0 && format == .default {
                res.append(str.lowercased())
                continue
            }
            res.append(str.capitalized)
        }
        return res.joined().uncapitalizeFirstLetter()
    }
}
