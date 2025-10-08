module OhMyCards

using Documenter
using ImageTransformations, ImageIO, Base64, FileIO # for resize
import Documenter: MarkdownAST

include("types.jl")
include("format_detection.jl")
include("html_embedding.jl")
include("content_conversion.jl")
include("path_generation.jl")
include("processor.jl")
include("ast_utils.jl")
include("build_step.jl")
include("cardmeta.jl")
include("overview.jl")

export ExampleConfig
export Feature, CopyPastableExample, Badge, JuliaFileBadge, DateBadge, AuthorBadge, LicenseBadge
export CoverImageConfig, CoverImageResult, CoverImageError, UnsupportedFormatError, ConversionError, PathGenerationError, validate_config
export detect_format, detect_format_with_fallback, MIME_MAPPING
export embeddable_html
export convert_to_format
export generate_filename, has_prettyurls, generate_relative_path, write_image_file, generate_and_write_image
export process_cover_image
end
