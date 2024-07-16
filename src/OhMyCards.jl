module OhMyCards

using Documenter
using ImageTransformations, ImageIO, Base64, FileIO # for resize
import Documenter: MarkdownAST

include("types.jl")
include("ast_utils.jl")
include("build_step.jl")
include("cardmeta.jl")
include("overview.jl")

export ExampleConfig
export Feature, CopyPastableExample, Badge, JuliaFileBadge, DateBadge, AuthorBadge, LicenseBadge
end
