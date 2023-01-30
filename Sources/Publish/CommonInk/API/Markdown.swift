/**
*  Adopted from Ink for CommonInk
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

///
/// A parsed Markdown value, which contains its rendered
/// HTML representation, as well as any metadata found at
/// the top of the Markdown document.
///
/// You create instances of this type by parsing Markdown
/// strings using `MarkdownParser`.
public struct CommonMarkdown {
    /// The HTML representation of the Markdown, ready to
    /// be rendered in a web browser.
    public var html: String
    /// The inferred title of the document, from any top-level
    /// heading found when parsing. If the Markdown text contained
    /// two top-level headings, then this property will contain
    /// the first one. Note that this property does not take modifiers
    /// into acccount.
    public var title: String? {
        get { titleStorage.title }
        set { overrideTitle(with: newValue) }
    }
    /// Any metadata values found at the top of the Markdown
    /// document. See this project's README for more information.
    public var metadata: [String : String]

    private var titleStorage = TitleStorage()

    internal init(html: String,
                  titleHeading: String?,
                  metadata: [String : String]) {
        self.html = html
        self.titleStorage = TitleStorage(titleHeading)
        self.metadata = metadata
    }
}

private extension CommonMarkdown {
    final class TitleStorage {
        var title: String?
        init(_ title: String? = nil) {
            self.title = title
        }
    }

    mutating func overrideTitle(with title: String?) {
        titleStorage = TitleStorage(title)
    }
}
