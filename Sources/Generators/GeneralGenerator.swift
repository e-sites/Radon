//
//  GeneralGenerator.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation
import Francium

class GeneralGenerator: Generator {
    var allowedExtensions: [String] { return [] }
    
    let config: Config

    required init(config: Config) {
        self.config = config
    }

    var name: String {
        return ""
    }

    func parse(folder: Folder) {
        let contents = [
            headerLines(fileName: Radon.fileName),
            "import Foundation",
            "",
            "public class \(Radon.fileName) {",
            "nonisolated(unsafe) public static var defaultPluralLocale = Locale.current".tabbed(1),
            "",
            "private init() { }".tabbed(1),
            "}"
        ]
        do {
            let file = File(path: "\(config.outputFolder)/\(Radon.fileName).swift")
            try file.write(string: contents.joined(separator: "\n"))
        } catch let error {
            Logger.fatalError("\(error)")
        }
    }
}
