//
//  ObjStruct.swift
//  Radon
//
//  Created by Bas van Kuijck on 10/10/2022.
//

import Foundation

class ObjStruct: CustomStringConvertible {
    private let _name: String?
    var subStructs: [ObjStruct] = []
    var superStruct: ObjStruct?
    var objects: [String] = []
    
    var name: String? {
        return self._name?.camelCased().appendIfFirstCharacterIsNumber(with: "_")
    }

    init(name: String? = nil) {
        self._name = name
    }

    var hasObjects: Bool {
        if objects.isEmpty {
            return !subStructs.filter { $0.hasObjects }.isEmpty
        }
        return true
    }

    var description: String {
        return "\(name ?? "nil"): \(hasObjects), imagesobjects \(objects), subStructs: \(subStructs)"
    }
    
    var superFolderName: String? {
        var superStruct: ObjStruct? = self
        var subNames: [String] = []
        while superStruct != nil {
            if let name = superStruct?._name {
                subNames.insert(name, at: 0)
            }
            superStruct = superStruct?.superStruct
        }
        subNames.removeFirst()
        if subNames.first == "Colors" {
            subNames.removeFirst()
        }
        if subNames.isEmpty {
            return nil
        }
        return subNames.joined(separator: "")
    }
}
