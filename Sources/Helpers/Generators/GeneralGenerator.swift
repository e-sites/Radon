//
//  GeneralGenerator.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation

class GeneralGenerator: Generator {
    let outputFolder: String

    var allowedExtensions: [String] { return [] }

    required init(outputFolder: String) {
        self.outputFolder = outputFolder
    }

    var name: String {
        return ""
    }

    func parse(folder: Folder) {
        let contents = [
            headerLines(fileName: Radon.fileName),
            "public struct \(Radon.fileName) {",
            "private init() { }".tabbed(1),
            "}"
        ]
        File(path: "\(outputFolder)/\(Radon.fileName).swift").write(contents.joined(separator: "\n"))
    }
}
