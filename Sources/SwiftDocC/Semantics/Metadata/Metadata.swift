/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation
import Markdown

/// A directive that contains various metadata about a page.
///
/// This directive acts as a container for metadata and configuration without any arguments of its own.
///
/// ## Topics
/// 
/// ### Child Directives
///
/// - ``DocumentationExtension``
/// - ``TechnologyRoot``
/// - ``DisplayName``
/// - ``PageImage``
/// - ``CustomMetadata``
/// - ``CallToAction``
/// - ``Availability``
/// - ``SupportedLanguage``
/// - ``PageKind``
/// - ``PageColor``
/// - ``TitleHeading``
/// - ``Redirect``
/// - ``Synonym``
public final class Metadata: Semantic, AutomaticDirectiveConvertible {
    public static let introducedVersion = "5.5"
    public let originalMarkup: BlockDirective
    
    /// Configuration that describes how this documentation extension file merges or overrides the in-source documentation.
    @ChildDirective
    var documentationOptions: DocumentationExtension? = nil
    
    /// Configuration to make this page root-level documentation.
    @ChildDirective
    var technologyRoot: TechnologyRoot? = nil
    
    /// Configuration to customize this page's symbol's display name.
    @ChildDirective
    var displayName: DisplayName? = nil
    
    /// The optional, custom image used to represent this page.
    @ChildDirective(requirements: .zeroOrMore)
    var pageImages: [PageImage]
    
    @ChildDirective(requirements: .zeroOrMore)
    var customMetadata: [CustomMetadata]

    @ChildDirective
    var callToAction: CallToAction? = nil

    @ChildDirective(requirements: .zeroOrMore)
    var availability: [Availability]

    @ChildDirective
    var pageKind: PageKind? = nil
    
    @ChildDirective(requirements: .zeroOrMore)
    var supportedLanguages: [SupportedLanguage]
    
    @ChildDirective
    var _pageColor: PageColor? = nil
    
    /// The optional, context-dependent color used to represent this page.
    var pageColor: PageColor.Color? {
        _pageColor?.color
    }

    @ChildDirective
    var titleHeading: TitleHeading? = nil

    @ChildDirective
    var redirects: [Redirect]? = nil
    
    @ChildDirective(requirements: .zeroOrMore)
    var synonyms: [Synonym]

    static var keyPaths: [String : AnyKeyPath] = [
        "documentationOptions"  : \Metadata._documentationOptions,
        "technologyRoot"        : \Metadata._technologyRoot,
        "displayName"           : \Metadata._displayName,
        "pageImages"            : \Metadata._pageImages,
        "customMetadata"        : \Metadata._customMetadata,
        "callToAction"          : \Metadata._callToAction,
        "availability"          : \Metadata._availability,
        "pageKind"              : \Metadata._pageKind,
        "supportedLanguages"    : \Metadata._supportedLanguages,
        "_pageColor"            : \Metadata.__pageColor,
        "titleHeading"          : \Metadata._titleHeading,
        "redirects"             : \Metadata._redirects,
        "synonyms"              : \Metadata._synonyms,
    ]
    
    @available(*, deprecated, message: "Do not call directly. Required for 'AutomaticDirectiveConvertible'.")
    init(originalMarkup: BlockDirective) {
        self.originalMarkup = originalMarkup
    }
    
    func validate(source: URL?, for bundle: DocumentationBundle, in context: DocumentationContext, problems: inout [Problem]) -> Bool {
        // Check that something is configured in the metadata block
        if documentationOptions == nil && technologyRoot == nil && displayName == nil && pageImages.isEmpty && customMetadata.isEmpty && callToAction == nil && availability.isEmpty && pageKind == nil && pageColor == nil && titleHeading == nil && redirects == nil && synonyms.isEmpty {
            let diagnostic = Diagnostic(
                source: source,
                severity: .information,
                range: originalMarkup.range,
                identifier: "org.swift.docc.\(Metadata.directiveName).NoConfiguration",
                summary: "\(Metadata.directiveName.singleQuoted) doesn't configure anything and has no effect"
            )
            
            let solutions = originalMarkup.range.map {
                [Solution(summary: "Remove this \(Metadata.directiveName.singleQuoted) directive.", replacements: [Replacement(range: $0, replacement: "")])]
            } ?? []
            problems.append(Problem(diagnostic: diagnostic, possibleSolutions: solutions))
        }
        
        validateDuplicates(in: pageImages, uniqueBy: \.purpose, keyName: "purpose", problems: &problems)
        validateDuplicates(in: availability, uniqueBy: \.platform, keyName: "platform", problems: &problems)
        validateDuplicates(in: synonyms, uniqueBy: \.language, keyName: "language", problems: &problems)
        
        return true
    }
    
    private func validateDuplicates<Directive: AutomaticDirectiveConvertible, Key: Hashable>(in directive: [Directive], uniqueBy key: ([Directive].Element) -> Key, keyName: String, problems: inout [Problem]) {
        let categorizedDirective = Dictionary(grouping: directive, by: key)

        for duplicateIntroduced in categorizedDirective.values {
            guard duplicateIntroduced.count > 1 else {
                continue
            }
            
            for duplicate in duplicateIntroduced {
                let diagnostic = Diagnostic(
                    source: duplicate.originalMarkup.nameLocation?.source,
                    severity: .warning,
                    range: duplicate.originalMarkup.range,
                    identifier: "org.swift.docc.\(Directive.self).Duplicate\(keyName.capitalized)",
                    summary: "Duplicate \(Directive.directiveName.singleQuoted) directive with '\(key(duplicate))' \(keyName)",
                    explanation: """
                    A documentation page can only contain a single \(Directive.directiveName.singleQuoted) directive for each \(keyName).
                    """
                )

                guard let range = duplicate.originalMarkup.range else {
                    problems.append(Problem(diagnostic: diagnostic))
                    continue
                }

                let solution = Solution(
                    summary: "Remove extraneous \(Directive.directiveName.singleQuoted) directive",
                    replacements: [
                        Replacement(range: range, replacement: "")
                    ]
                )

                problems.append(Problem(diagnostic: diagnostic, possibleSolutions: [solution]))
            }
        }
    }
}
