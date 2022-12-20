//
//  main.swift
//  Natrium
//
//  Created by Bas van Kuijck on 07/06/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

import Foundation
import CommandLineKit

let radon: Radon

#if !DEBUG
let cli = CommandLineKit.CommandLine()

let folderOption = StringOption(shortFlag: "f",
                                longFlag: "folder",
                                required: true,
                                helpMessage: "The folder to scan for assets")


let outOption = StringOption(shortFlag: "o",
                             longFlag: "output",
                             required: false,
                             helpMessage: "The folder to write the Radon.swift files to")


let bundleOption = StringOption(shortFlag: "b",
                             longFlag: "bundle",
                             required: false,
                             helpMessage: "The bundle to be used (default: Bundle.main)")


let watchOption = BoolOption(shortFlag: "w",
                             longFlag: "watch",
                             required: false,
                             helpMessage: "Automatically watch the `folder`")


let removeFoldersInFileNameOption = BoolOption(shortFlag: "r",
                             longFlag: "remove_foldernames",
                             required: false,
                             helpMessage: "Remove the name of the folder from the filename")


let hideDateInHeader = BoolOption(shortFlag: "h",
                             longFlag: "hide_update_datetime_in_header",
                             required: false,
                             helpMessage: "Hides the date/time in the generated swift files' header")

let stripAssetsOption = BoolOption(shortFlag: "s",
                             longFlag: "strip_xcassets",
                             required: false,
                             helpMessage: "Remove Assets.xcassets from the image generator")

let fullLocalizationKeysOption = BoolOption(shortFlag: "l",
                             longFlag: "full_localization_keys",
                             required: false,
                             helpMessage: "Use R.strings.full_localization_key output instead of R.strings.some.key")

cli.addOptions(folderOption, outOption, bundleOption, hideDateInHeader, watchOption, removeFoldersInFileNameOption, stripAssetsOption, fullLocalizationKeysOption)

do {
    try cli.parse()
} catch {
    print("Radon version: \(Radon.version)")
    print("")
    cli.printUsage(error)
    exit(EX_USAGE)
}


radon = Radon(
    folder: folderOption.value!,
    outputFolder: outOption.value ?? "./",
    bundleName: bundleOption.value ?? "Bundle.main",
    watch: watchOption.wasSet,
    removeFolderName: removeFoldersInFileNameOption.wasSet,
    stripXCAssets: stripAssetsOption.wasSet,
    fullLocalizationKeys: fullLocalizationKeysOption.wasSet,
    hideDateInHeader: hideDateInHeader.wasSet
)
#else
radon = Radon(
    folder: "/Users/bvkuijck/Desktop/workspace/ios/#library/Radon/RadonExample/RadonExample/Resources",
    outputFolder: "/Users/bvkuijck/Desktop/workspace/ios/#library/Radon/RadonExample/Generated/",
    bundleName: "Bundle.main",
    watch: false,
    removeFolderName: true,
    stripXCAssets: true,
    fullLocalizationKeys: true
)
#endif
radon.run()
