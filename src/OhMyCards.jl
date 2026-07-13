module OhMyCards

using Documenter
using ImageTransformations, ImageIO, Base64, FileIO # for resize
import Documenter: MarkdownAST

include("renderers.jl")
include("types.jl")
include("build_step.jl")
include("cardmeta.jl")
include("overview.jl")

export ExampleConfig
export GalleryRenderer, Card, emit_gallery, DocumenterGallery, VitepressGallery
end
