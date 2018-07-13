//
//  main.swift
//  Natrium
//
//  Created by Bas van Kuijck on 07/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

import Foundation
import CommandLineKit
import AppKit

let cli = CommandLineKit.CommandLine()

let folderOption = StringOption(shortFlag: "f",
                                longFlag: "folder",
                                required: true,
                                helpMessage: "The folder to scan")


let outOption = StringOption(shortFlag: "o",
                             longFlag: "out",
                             required: false,
                             helpMessage: "The folder to write the R.swift file to")


let watchOption = BoolOption(shortFlag: "w",
                             longFlag: "watch",
                             required: false,
                             helpMessage: "Automatically watch the 'folder'")


cli.addOptions(folderOption, outOption, watchOption)

do {
    try cli.parse()
} catch {
    print("Radon version: \(Radon.version)")
    print("")
    cli.printUsage(error)
    exit(EX_USAGE)
}


let radon = Radon(folder: folderOption.value!, outputFolder: outOption.value ?? "./", watch: watchOption.wasSet)
if watchOption.wasSet {
    RunLoop.main.run()
}