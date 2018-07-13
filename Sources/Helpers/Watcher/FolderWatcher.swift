//
//  FolderWatcher.swift
//  Radon
//
//  Created by Bas van Kuijck on 12/07/2018.
//

import Foundation

class FolderWatcher {
    private let folderFile: File
    private(set) var isWatching = false
    private(set) var isScanning = false

    private var _timer: Timer?

    private var _md5 = ""

    private var _previousMD5: String?

    init(file: File) {
        self.folderFile = file
    }

    func start() {
        if isWatching {
            return
        }
        isWatching = true
        _startScan()
    }

    func stop() {
        isWatching = false
        _timer?.invalidate()
        _timer = nil
    }

    private func _startScan() {
        _timer = Timer(timeInterval: 1, target: self, selector: #selector(_scan), userInfo: nil, repeats: false)
        RunLoop.main.add(_timer!, forMode: .commonModes)
    }

    @objc
    private func _scan() {
        DispatchQueue(label: "com.esites.library.radon", qos: .background).async {
            if !self.isWatching {
                return
            }
            if self.isScanning {
                return
            }
            self._md5 = ""
            self.isScanning = true
            self._parseFolder(self.folderFile)
            if self._md5 != self._previousMD5 {
                self._onChanges?()
                self._previousMD5 = self._md5
            }
            self.isScanning = false
            self._startScan()
        }
    }

    private func _parseFolder(_ dir: File) {
        Dir.glob("\(dir.path)/*")
            .filter { $0.name != ".DS_Store" }
            .forEach { file in
                _md5 = "\(_md5)\(file.path)".md5
                if file.isDirectory {
                    _parseFolder(file)
                }
        }
    }

    private var _onChanges: (() -> Void)?

    func onChanges(_ closure: @escaping (() -> Void)) {
        _onChanges = closure
    }
}
