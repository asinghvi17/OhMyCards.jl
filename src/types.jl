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


# Cover Image System Types

struct CoverImageConfig
    # Dimensions
    target_height::Union{Int, Nothing}
    target_width::Union{Int, Nothing}
    maintain_aspect_ratio::Bool
    
    # Format preferences
    preferred_format::Union{String, Nothing}  # "png", "jpeg", "webp", "svg", "gif", "mp4"
    fallback_format::String
    
    # Quality settings
    jpeg_quality::Int
    webp_quality::Int
    
    # Video settings
    mp4_fps::Int
    mp4_duration::Union{Float64, Nothing}  # Auto-detect if nothing
    
    # HTML embedding
    video_autoplay::Bool
    video_loop::Bool
    video_muted::Bool
    video_controls::Bool
    
    # Path generation
    filename_prefix::String
    use_content_hash::Bool
end

struct CoverImageResult
    file_path::String
    relative_url::String
    mime_type::MIME
    html_embed::String
    metadata::Dict{Symbol, Any}
end

# Cover Image Exception Types
abstract type CoverImageError <: Exception end

struct UnsupportedFormatError <: CoverImageError
    content_type::Type
    requested_format::String
end

struct ConversionError <: CoverImageError
    content_type::Type
    format::String
    original_error::Exception
end

struct PathGenerationError <: CoverImageError
    reason::String
end

# Configuration validation functions
function validate_config(config::CoverImageConfig)
    # Validate dimensions
    if config.target_height !== nothing && config.target_height <= 0
        throw(ArgumentError("target_height must be positive, got $(config.target_height)"))
    end
    
    if config.target_width !== nothing && config.target_width <= 0
        throw(ArgumentError("target_width must be positive, got $(config.target_width)"))
    end
    
    # Validate format preferences
    valid_formats = ["png", "jpeg", "webp", "svg", "gif", "mp4"]
    if config.preferred_format !== nothing && !(config.preferred_format in valid_formats)
        throw(ArgumentError("preferred_format must be one of $valid_formats, got $(config.preferred_format)"))
    end
    
    if !(config.fallback_format in valid_formats)
        throw(ArgumentError("fallback_format must be one of $valid_formats, got $(config.fallback_format)"))
    end
    
    # Validate quality settings
    if !(1 <= config.jpeg_quality <= 100)
        throw(ArgumentError("jpeg_quality must be between 1 and 100, got $(config.jpeg_quality)"))
    end
    
    if !(1 <= config.webp_quality <= 100)
        throw(ArgumentError("webp_quality must be between 1 and 100, got $(config.webp_quality)"))
    end
    
    # Validate video settings
    if config.mp4_fps <= 0
        throw(ArgumentError("mp4_fps must be positive, got $(config.mp4_fps)"))
    end
    
    if config.mp4_duration !== nothing && config.mp4_duration <= 0
        throw(ArgumentError("mp4_duration must be positive, got $(config.mp4_duration)"))
    end
    
    return true
end

# Constructor with validation - override the default constructor
function CoverImageConfig(;
    target_height::Union{Int, Nothing} = 600,
    target_width::Union{Int, Nothing} = nothing,
    maintain_aspect_ratio::Bool = true,
    preferred_format::Union{String, Nothing} = nothing,
    fallback_format::String = "png",
    jpeg_quality::Int = 85,
    webp_quality::Int = 80,
    mp4_fps::Int = 30,
    mp4_duration::Union{Float64, Nothing} = nothing,
    video_autoplay::Bool = true,
    video_loop::Bool = true,
    video_muted::Bool = true,
    video_controls::Bool = false,
    filename_prefix::String = "",
    use_content_hash::Bool = true
)
    config = CoverImageConfig(
        target_height, target_width, maintain_aspect_ratio,
        preferred_format, fallback_format, jpeg_quality, webp_quality,
        mp4_fps, mp4_duration, video_autoplay, video_loop, video_muted,
        video_controls, filename_prefix, use_content_hash
    )
    validate_config(config)
    return config
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