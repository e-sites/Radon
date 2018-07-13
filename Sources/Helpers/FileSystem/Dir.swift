//
//  Dir.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation

// MARK: - Dir: Class
// --------------------------------------------------------

class Dir {
    static func create(_ path: String) {
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
    }

    @discardableResult
    static func glob(_ pattern: String, handler: ((File) -> Void)? = nil) -> [File] {
        let pattern = pattern.replacingOccurrences(of: "*", with: "(.+?)")
        let directory = File.dirName(of: pattern)
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: directory)
                .map { "\(directory)/\($0)" }
            var returnArray: [File] = []
            for file in files where file =~ pattern {
                let fileObj = File(path: file)
                returnArray.append(fileObj)
                handler?(fileObj)
            }

            return returnArray
        } catch let error {
            Logger.fatalError("\(error)")
            return []
        }
    }

    static func clearContents(of path: String) {
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(atPath: path)
                .map { "\(path)/\($0)" }
            for file in files {
                try fileManager.removeItem(atPath: file)
            }
        } catch let error {
            Logger.fatalError("\(error)")
        }
    }

    static func dirName(path: String) -> String {
        var path = path
        if path.last == "/" {
            _ = path.removeLast()
        }
        return path
    }
}
