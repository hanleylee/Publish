/**
 *  Adopted from Ink for CommonInk
 *  Copyright (c) John Sundell 2019
 *  MIT license, see LICENSE file for details
 */

import Markdown

///
/// A parser used to convert Markdown text into HTML.
///
/// You can use an instance of this type to either convert
/// a Markdown string into an HTML string, or into a `Markdown`
/// value, which also contains any metadata values found in
/// the parsed Markdown text.
///
/// To customize how this parser performs its work, attach
/// a `Modifier` using the `addModifier` method.
public struct MarkdownParser {
    private var modifiers: ModifierCollection

    /// Initialize an instance, optionally passing an array
    /// of modifiers used to customize the parsing process.
    public init(modifiers: [Modifier] = []) {
        self.modifiers = ModifierCollection(modifiers: modifiers)
    }

    /// Add a modifier to this parser, which can be used to
    /// customize the parsing process. See `Modifier` for more info.
    public mutating func addModifier(_ modifier: Modifier) {
        modifiers.insert(modifier)
    }

    /// Convert a Markdown string into HTML, discarding any metadata
    /// found in the process. To preserve the Markdown's metadata,
    /// use the `parse` method instead.
    public func html(from markdown: String) -> String {
        parse(markdown).html
    }

    /// Parse a Markdown string into a `Markdown` value, which contains
    /// both the HTML representation of the given string, and also any
    /// metadata values found within it.
    public func parse(_ markdown: String) -> CommonMarkdown {
        var metadata: [String: String] = [:]

        var document = Document(parsing: markdown)

        if let _ = document.child(at: 0) as? ThematicBreak,
           let heading2 = document.child(at: 1) as? Heading,
           let heading2Range = heading2.range,
           var metadataLines = markdown.substring(in: heading2Range)?.trimmingWhitespaces().split(separator: "\n").map({ $0.trimmingWhitespaces() })
        {
            // fix no empty line between "---" and first content line of md check if contains 0 or 1 "---"
            if metadataLines.filter({ $0 == "---" }).count <= 1 {
                metadataLines.removeLast(metadataLines.count - (metadataLines.firstIndex(where: { $0 == "---" }) ?? metadataLines.count))
                if metadataLines.map({ $0.contains(":") }).reduce(into: true, { $0 = $0 && $1 }) {
                    metadata = metadataLines.reduce(into: [String: String]()) { dictionary, string in
                        let firstColonIndex = string.firstIndex(of: ":")!
                        let key = String(string[string.startIndex..<firstColonIndex].trimmingWhitespaces())
                        let value = String(string[string.index(firstColonIndex, offsetBy: 1)..<string.endIndex].trimmingWhitespaces())
                        dictionary[key] = value
                    }
                    // Modify Metadata
                    modifiers.applyModifiers(for: .metadataKeys) { modifier in
                        for (key, value) in metadata {
                            let newKey = modifier.closure((key, Substring(key)))
                            metadata[key] = nil
                            metadata[newKey] = value
                        }
                    }

                    modifiers.applyModifiers(for: .metadataValues) { modifier in
                        metadata = metadata.mapValues { value in
                            modifier.closure((value, Substring(value)))
                        }
                    }
                    document.replaceChildrenInRange(0..<2, with: [])
                }
            }
        }
        var htmlConverter = HTMLVisitor(sourceText: markdown, modifiers: modifiers)
        let htmlText = htmlConverter.visit(document) as String

        var headingFinder = HeadingFinder()
        headingFinder.visit(document)

        return CommonMarkdown(
            html: htmlText,
            titleHeading: headingFinder.heading1,
            metadata: metadata
        )
    }
}

internal struct HeadingFinder: MarkupWalker {
    var heading1: String? = nil
    mutating func visitHeading(_ heading: Heading) {
        if heading1 == nil && heading.level == 1 {
            heading1 = heading.plainText
        }
    }
}
