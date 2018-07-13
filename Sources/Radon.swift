//
//  Radon.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation

class Radon {
    static var version: String = "1.1.0"

    static var fileName = "Radon"

    private let mainFolder: String
    private let outputFolder: String
    private var _countFiles = 0
    private var _shouldWatch = false
    private var _countFolders = 0

    init(folder aFolder: String, outputFolder: String, watch: Bool = true) {
        if !File(path: outputFolder).isDirectory {
            Logger.fatalError("'\(outputFolder)' does not exist")
        }
        var aFolder = aFolder
        if aFolder.hasSuffix("/") {
            aFolder.removeLast()
        }
        self.mainFolder = aFolder
        Logger.log(Logger.colorWrap(text: "Running Radon (v\(Radon.version))", in: "1"))
        if watch {
            Logger.log("Watching " + Logger.colorWrap(text: aFolder, in: "1;94") + " for changes")
            Logger.log("Press " + Logger.colorWrap(text: " ^ + C ", in: "1;97;100") + " to close the automatic builder")
        }
        Logger.log("")

        aFolder = outputFolder
        if aFolder.hasSuffix("/") {
            aFolder.removeLast()
        }
        self.outputFolder = aFolder
        _shouldWatch = watch
    }

    func run() {

        let mainFolderFile = File(path: mainFolder)

        let fire: (() -> Void) = {
            self._countFiles = 0
            self._countFolders = 0
            let folder = Folder(name: "")
            self.parseFolder(mainFolderFile, folder: folder)
            GeneralGenerator(outputFolder: self.outputFolder).parse(folder: folder)
            let imageGenerator = ImageGenerator(outputFolder: self.outputFolder)
            imageGenerator.parse(folder: folder)
            Logger.log(Logger.colorWrap(text: "Generated new ", in: "95") +
                Logger.colorWrap(text: Radon.fileName + ".swift", in: "4;95") +
                Logger.colorWrap(text: " (Scanned \(self._countFolders) folders, \(self._countFiles) files)", in: "90")
            )

        }

        if _shouldWatch {
            let watcher = FolderWatcher(file: mainFolderFile)
            watcher.start()
            watcher.onChanges(fire)

            RunLoop.main.run()
        } else {
            fire()
        }
        
    }

    func parseFolder(_ dir: File, folder: Folder) {
        Dir.glob("\(dir.path)/*")
            .filter { $0.name != ".DS_Store" }
            .forEach { file in
                if file.isDirectory {
                    if file.extension == "appiconset" || file.extension == "launchimage" {

                    } else if file.extension == "imageset" {
                        folder.files.append(file)
                        self._countFiles += 1
                    } else {
                        let newFolder = Folder(name: file.name)
                        folder.subFolders.append(newFolder)
                        self._countFolders += 1
                        parseFolder(file, folder: newFolder)
                    }
                } else {
                    folder.files.append(file)
                    self._countFiles += 1
                }
        }
    }
}
