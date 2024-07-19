abstract type Feature end

struct CopyPastableExample <: Feature end

abstract type Badge <: Feature end
struct JuliaFileBadge <: Badge end
struct DateBadge <: Badge end
struct AuthorBadge <: Badge 
    default_author::String
end
struct LicenseBadge <: Badge 
    name::String
    link::String
end


@kwdef struct ExampleConfig <: Documenter.Plugin
    """
    The features to be included in the example gallery.
    """
    features::Vector{Feature} = Feature[CopyPastableExample()]
    """
    The known examples to be included in the example gallery.
    """
    known_examples::Vector = []
    "Whether to inject scoped CSS into a div enclosing the output of each gallerybox "
    inject_scoped_css = false
    "For internal use only, acts as a global cache to store the results from `@cardmeta` for each page"
    gallery_dict::Dict = Dict{String, Any}()
end