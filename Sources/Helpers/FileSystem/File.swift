//
//  File.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation

// MARK: - File: Class
// --------------------------------------------------------

class File: CustomStringConvertible {
    let path: String

    init(path: String) {
        self.path = path
    }

    static func file(_ path: String) -> Bool {
        return exists(at: path)
    }

    static func exists(at path: String) -> Bool {
        return File(path: path).isExisting
    }

    static func read(path: String) -> String? {
        return File(path: path).contents
    }

    static func dirName(of path: String) -> String {
        return File(path: path).dirName
    }

    static func open(_ path: String) -> File {
        return File(path: path)
    }

    static func remove(_ path: String) {
        File(path: path).remove()
    }

    static func copy(_ path: String, `to` toPath: String) {
        File(path: path).copy(to: toPath)
    }

    static func copy(_ path: String, `to` toFile: File) {
        File(path: path).copy(to: toFile)
    }

    var isDirectory: Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            return isDir.boolValue
        } else {
            return false
        }
    }

    var fileName: String? {
        var exp = name.components(separatedBy: ".")
        exp.removeLast()
        return exp.joined(separator: ".")
    }

    var `extension`: String? {
        return name.components(separatedBy: ".").last
    }

    var description: String {
        return path
    }
}


// MARK: - File: Instance
// --------------------------------------------------------

extension File {
    func write(_ string: String) {
        write(string.data(using: .utf8) ?? Data())
    }

    func write(_ data: Data) {
        let url = URL(fileURLWithPath: path)
        try? data.write(to: url)
    }

    func remove() {
        try? FileManager.default.removeItem(atPath: path)
    }

    var dirName: String {
        if isDirectory {
            return path
        }
        var url = URL(fileURLWithPath: path)
        url.deleteLastPathComponent()
        return url.path
    }

    var name: String {
        let url = URL(fileURLWithPath: path)
        return url.lastPathComponent
    }

    var contents: String? {
        guard let data = self.data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    var data: Data? {
        return FileManager.default.contents(atPath: path)
    }

    var isExisting: Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    func append(text: String) {
        if !isExisting {
            write(text)
            return
        }
        let data = text.data(using: .utf8) ?? Data()
        guard let fileHandle = FileHandle(forUpdatingAtPath: path) else {
            write(text)
            return
        }
        defer {
            fileHandle.closeFile()
        }
        fileHandle.seekToEndOfFile()
        fileHandle.write(data)
    }

    func copy(`to` path: String) {
        copy(to: File(path: path))
    }

    func copy(`to` file: File) {
        do {
            try FileManager.default.copyItem(atPath: path, toPath: file.path)
        } catch let error {
            Logger.fatalError("Error copying \(path) to \(file.path): \(error)")
        }
    }
}
