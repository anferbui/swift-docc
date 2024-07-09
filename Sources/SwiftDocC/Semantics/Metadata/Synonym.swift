/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation
import Markdown


extension Metadata {
    /// A directive that controls TODO.
    ///
    /// TODO.
    ///
    /// ```
    /// @Metadata {
    ///     @Synonym(language: swift) {
    ///         ``MyApp/MyClass/property``
    ///     }
    /// }
    /// ```
    ///
    /// This directive supports any language identifier, but only the following are currently supported
    /// by Swift-DocC Render:
    ///
    /// | Identifier                                 | Language               |
    /// | --------------------------------- | ----------------------|
    /// | `swift`                                | Swift                       |
    /// | `objc`, `objective-c`   | Objective-C            |
    public final class Synonym: Semantic, AutomaticDirectiveConvertible, MarkupContaining {
        public static let introducedVersion = "6.1"
                
        // Directive parameter definition
        
        /// The language identifier of the symbol to define as a synonym.
        @DirectiveArgumentWrapped(parseArgument: parseSourceLanguage(_:_:))
        public var language: SourceLanguage
        
        /// The inline markup contained in this 'Synonym' directive.
        ///
        /// This content should not be rendered directly, instead the documentation link inside should be extracted
        /// and linked to from the language-switch toggle.
        @ChildMarkup
        public private(set) var content: MarkupContainer
        
        static var keyPaths: [String : AnyKeyPath] = [
            "language": \Synonym._language,
            "content" : \Synonym._content
        ]
        
        // Boiler-plate required by conformance to MarkupContaining
                
        override var children: [Semantic] {
            return [content]
        }

        var childMarkup: [Markup] {
            return content.elements
        }
        
        // Boiler-plate required by conformance to AutomaticDirectiveConvertible
        
        public var originalMarkup: Markdown.BlockDirective

        @available(*, deprecated, message: "Do not call directly. Required for 'AutomaticDirectiveConvertible")
        init(originalMarkup: Markdown.BlockDirective) {
            self.originalMarkup = originalMarkup
        }
        
        // Additional validation of the directive
        
        func validate(source: URL?, for bundle: DocumentationBundle, in context: DocumentationContext, problems: inout [Problem]) -> Bool {
            _ = Semantic.Analyses.HasExactlyOneLink<Synonym>(
                severityIfNotFound: .warning
            ).analyze(
                originalMarkup,
                children: originalMarkup.children,
                source: source,
                for: bundle,
                in: context,
                problems: &problems
            )
            
            return true
        }
    }
}

