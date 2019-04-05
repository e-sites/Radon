//
//  GeneralGenerator.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation
import Francium

class GeneralGenerator: Generator {
    let outputFolder: String
    let removeFolderName: Bool

    var allowedExtensions: [String] { return [] }

    required init(outputFolder: String, removeFolderName: Bool = false) {
        self.removeFolderName = removeFolderName
        self.outputFolder = outputFolder
    }

    var name: String {
        return ""
    }

    func parse(folder: Folder) {
        let contents = [
            headerLines(fileName: Radon.fileName),
            "struct \(Radon.fileName) {",
            "private init() { }".tabbed(1),
            "}"
        ]
        do {
            let file = File(path: "\(outputFolder)/\(Radon.fileName).swift")
            try file.write(string: contents.joined(separator: "\n"))
        } catch let error {
            Logger.fatalError("\(error)")
        }
    }
}
