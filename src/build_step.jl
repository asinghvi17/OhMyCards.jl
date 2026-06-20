"""
    ExampleProcessing <: Documenter.Builder.DocumenterPipeline

Per-page prep, run at priority 1.2 (after `doctest`, before `expand_templates`):
moves cardmeta blocks to page end, generates one for example pages that lack it,
and adds example pages to `expandfirst`.
"""
abstract type ExampleProcessing <: Documenter.Builder.DocumentPipeline end

Documenter.Selectors.order(::Type{ExampleProcessing}) = 1.2 # after doctest, before expand templates.

function _is_cardmeta_block(x)
    return x.element isa MarkdownAST.CodeBlock && Base.occursin("@cardmeta", x.element.info)
end

function Documenter.Selectors.runner(::Type{ExampleProcessing}, doc::Documenter.Document)
    settings = Documenter.getplugin(doc, ExampleConfig)
    for (filename, page) in doc.blueprint.pages
        cardmeta_blocks = filter(_is_cardmeta_block, collect(page.mdast.children))
        # A page is an example page if it has a cardmeta block or lives under examples/.
        has_cardmeta_blocks   = !isempty(cardmeta_blocks)
        is_known_example_page = Base.occursin("examples", splitdir(page.build)[1]) || page.build in settings.known_examples
        is_example_page = is_known_example_page || has_cardmeta_blocks
        is_example_page || continue
        if has_cardmeta_blocks
            # Move the cardmeta block to page end. Guard: if it is already last,
            # insert_after! would unlink! then re-insert it, corrupting the tree
            # and silently dropping the block.
            if first(cardmeta_blocks) !== last(page.mdast.children)
                MarkdownAST.insert_after!(last(page.mdast.children), first(cardmeta_blocks))
            end
        elseif is_known_example_page # inject an empty cardmeta block at page end
            MarkdownAST.insert_after!(last(page.mdast.children), MarkdownAST.@ast MarkdownAST.CodeBlock("@cardmeta", ""))
        end
        # expandfirst so cardmeta blocks are evaluated before any overviewgallery.
        # (is_example_page is guaranteed true here — line above continues otherwise.)
        if !(filename in doc.user.expandfirst)
            push!(doc.user.expandfirst, filename)
        end
    end
end
