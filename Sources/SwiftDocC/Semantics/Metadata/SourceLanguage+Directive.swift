/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation


// Initializer delegation cannot be nested with the `??` coalescing operator, so instead of extending ``SourceLanguage`` to conform to ``DirectiveArgumentValueConvertible``, we define a function to parse the argument value.
func parseSourceLanguage(_ bundle: DocumentationBundle, _ argumentValue: String) -> SourceLanguage? {
    SourceLanguage(knownLanguageIdentifier: argumentValue) ?? SourceLanguage(id: argumentValue)
}

// Conform to ``CustomStringConvertible`` to have a nice description of the type for any generated diagnostics.
extension SourceLanguage: CustomStringConvertible {
    public var description: String {
        self.name
    }
}
