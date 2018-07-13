//
//  FileHelper.swift
//  CommandLineKit
//
//  Created by Bas van Kuijck on 20/10/2017.
//

import Foundation

class FileHelper {
    static func write(filePath: String, contents: String) {
        let file = File.open(filePath)
        if file.isExisting {
            file.chmod("7777")
        }
        file.write(contents)
        file.touch()
        file.chmod("+x")
    }
}
