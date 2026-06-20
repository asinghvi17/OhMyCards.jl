@kwdef struct ExampleConfig <: Documenter.Plugin
    """
    The known examples to be included in the example gallery.
    """
    known_examples::Vector = []
    "Strategy object controlling how `@overviewgallery` emits the gallery markup."
    renderer::GalleryRenderer = DocumenterGallery()
    "For internal use only, acts as a global cache to store the results from `@cardmeta` for each page"
    gallery_dict::Dict = Dict{String, Any}()
end