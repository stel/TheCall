//
//  Errors.swift
//  TheCall
//
//  Created by Dmitry Obukhov on 15/03/16.
//  Copyright © 2016 Dmitry Obukhov. All rights reserved.
//

import Foundation

final class BlueScreenOfDeath {
    
    static func show(reason reason: String? = nil) {
        fatalError("Looks like there is a critical error for our small test app :( \(reason?.stringByAppendingString(". ") ?? "")See stack trace for more info.")
    }
    
}
