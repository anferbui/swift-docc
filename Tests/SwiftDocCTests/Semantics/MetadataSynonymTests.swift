/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2024 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation
import XCTest
import Markdown

@testable import SwiftDocC

class MetadataSynonymTests: XCTestCase {
    /// Basic validity test for giving several directives.
    func testMultipleSynonymDirectives() throws {
        let source = """
        @Metadata {
            @Synonym(language: objc) {
                ``MyClass/property``
            }
            @Synonym(language: swift) {
                <doc://org.swift.documentation/MyClass/property>
            }
        }
        """
        try assertValidDirective(Metadata.self, source: source) { (directive, _) in
            let synonyms = try XCTUnwrap(directive?.synonyms)
            XCTAssertEqual(synonyms.count, 2)
            
            let contents = synonyms.map { $0.content.dump() }
            // FIXME: This assertion is incorrect
            XCTAssertEqual(contents, [
                "``MyClass/property``",
                "<doc://org.swift.documentation/MyClass/property>"
            ])

            let languages = synonyms.map { $0.language }
            XCTAssertEqual(languages, [.objectiveC, .swift])
        }
    }
    
    func testDuplicateSynonymDirectives() throws {
        let source = """
        @Metadata {
            @Synonym(language: objc) {
                ``MyClass/property``
            }
            @Synonym(language: objc) {
                <doc://org.swift.documentation/MyClass/property>
            }
        }
        """
        try assertDirective(Metadata.self, source: source) { (directive, problems) in
            XCTAssertEqual(2, problems.count)
            
            let diagnosticIdentifiers = Set(problems.map { $0.diagnostic.identifier })
            XCTAssertEqual(diagnosticIdentifiers, ["org.swift.docc.\(Metadata.Synonym.self).DuplicateLanguage"])
        }
    }
    
    func testObjCAliasesInSynonymDirective() throws {
        for alias in SourceLanguage.objectiveC.idAliases {
            let source = """
            @Synonym(language: \(alias)) {
                ``MyClass/property``
            }
            """
            try assertValidDirective(Metadata.Synonym.self, source: source) { (directive, _) in
                XCTAssertEqual(directive?.language, .objectiveC)
            }
        }
    }
    
    func testUnknownSourceLanguageInSynonymDirective() throws {
        let source = """
        @Synonym(language: unknown) {
            ``MyClass/property``
        }
        """
        try assertValidDirective(Metadata.Synonym.self, source: source) { (directive, _) in
            XCTAssertEqual(directive?.language.id, "unknown")
        }
    }
    
    func assertDirective<Directive: AutomaticDirectiveConvertible>(_ type: Directive.Type, source: String, assertion assert: (Directive?, [Problem]) throws -> Void) throws {
        let document = Document(parsing: source, options: .parseBlockDirectives)
        let directive = document.child(at: 0) as? BlockDirective
        XCTAssertNotNil(directive)

        let (bundle, context) = try testBundleAndContext(named: "AvailabilityBundle")

        try directive.map { directive in
            var problems = [Problem]()
            XCTAssertEqual(Directive.directiveName, directive.name)
            let converted = Directive(from: directive, source: nil, for: bundle, in: context, problems: &problems)
            try assert(converted, problems)
        }
    }

    func assertValidDirective<Directive: AutomaticDirectiveConvertible>(
        _ type: Directive.Type, source: String,
        assertion assert: ((Directive?, [Problem]) throws -> Void)? = nil
    ) throws {
        try assertDirective(type, source: source) { directive, problems in
            XCTAssertNotNil(directive)
            XCTAssert(problems.isEmpty)
            
            if let assert {
                try assert(directive, problems)
            }
        }
    }
}
