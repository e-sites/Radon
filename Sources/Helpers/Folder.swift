//
//  Folder.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation
import Francium

class Folder: CustomStringConvertible {
    var files: [File] = []
    var subFolders: [Folder] = []
    let name: String

    init(name: String) {
        self.name = name
    }

    var description: String {
        return "Name: \(name), Files: \(files), subFolders: \(subFolders)"
    }
}
