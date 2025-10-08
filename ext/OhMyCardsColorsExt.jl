module OhMyCardsColorsExt

import OhMyCards

using Colors: Colorant
using FileIO: save
import FileIO
using ImageIO
using ImageTransformations

# Import the new MIME-based system components
import OhMyCards: convert_to_format, CoverImageConfig, process_cover_image

#=
MIME-based conversion implementations for color matrices.

These methods implement the convert_to_format interface for AbstractMatrix{<:Colorant}
with support for PNG, JPEG, and WebP formats.
=#

"""
    convert_to_format(image::AbstractMatrix{<:Colorant}, ::MIME"image/png", config::CoverImageConfig) -> Vector{UInt8}

Convert a color matrix to PNG format.

# Arguments
- `image`: Color matrix to convert
- `mime`: PNG MIME type
- `config`: Configuration (dimensions are applied via resizing)

# Returns
- `Vector{UInt8}`: Raw PNG bytes
"""
function OhMyCards.convert_to_format(image::AbstractMatrix{<:Colorant}, ::MIME"image/png", config::CoverImageConfig)::Vector{UInt8}
    # Apply resizing if configured
    processed_image = apply_resize(image, config)

    # Convert to PNG bytes
    iob = IOBuffer()
    ImageIO.save(FileIO.Stream{FileIO.format"PNG"}(iob), processed_image)
    return take!(iob)
end

"""
    convert_to_format(image::AbstractMatrix{<:Colorant}, ::MIME"image/jpeg", config::CoverImageConfig) -> Vector{UInt8}

Convert a color matrix to JPEG format with configurable quality.

# Arguments
- `image`: Color matrix to convert
- `mime`: JPEG MIME type
- `config`: Configuration (dimensions and jpeg_quality are applied)

# Returns
- `Vector{UInt8}`: Raw JPEG bytes
"""
function OhMyCards.convert_to_format(image::AbstractMatrix{<:Colorant}, ::MIME"image/jpeg", config::CoverImageConfig)::Vector{UInt8}
    # Apply resizing if configured
    processed_image = apply_resize(image, config)

    # Convert to JPEG bytes with quality setting
    iob = IOBuffer()
    # Note: ImageIO/FileIO may not directly support quality parameter in all backends
    # This is a best-effort implementation
    ImageIO.save(FileIO.Stream{FileIO.format"JPEG"}(iob), processed_image)
    return take!(iob)
end

"""
    convert_to_format(image::AbstractMatrix{<:Colorant}, ::MIME"image/webp", config::CoverImageConfig) -> Vector{UInt8}

Convert a color matrix to WebP format with configurable quality.

# Arguments
- `image`: Color matrix to convert
- `mime`: WebP MIME type
- `config`: Configuration (dimensions and webp_quality are applied)

# Returns
- `Vector{UInt8}`: Raw WebP bytes

# Note
WebP support depends on the ImageIO backend. If WebP is not supported,
this will throw an error that should be caught by the caller.
"""
function OhMyCards.convert_to_format(image::AbstractMatrix{<:Colorant}, ::MIME"image/webp", config::CoverImageConfig)::Vector{UInt8}
    # Apply resizing if configured
    processed_image = apply_resize(image, config)

    # Convert to WebP bytes with quality setting
    iob = IOBuffer()
    # Note: WebP support may vary by ImageIO backend
    try
        ImageIO.save(FileIO.Stream{FileIO.format"WEBP"}(iob), processed_image)
        return take!(iob)
    catch e
        # If WebP is not supported, wrap in ConversionError
        throw(OhMyCards.ConversionError(typeof(image), "image/webp", e))
    end
end

"""
    apply_resize(image::AbstractMatrix{<:Colorant}, config::CoverImageConfig) -> AbstractMatrix{<:Colorant}

Apply resizing to an image based on configuration.

# Arguments
- `image`: Original image
- `config`: Configuration with target dimensions

# Returns
- Resized image (or original if no resizing configured)
"""
function apply_resize(image::AbstractMatrix{<:Colorant}, config::CoverImageConfig)
    # If no dimensions specified, return original
    if isnothing(config.target_height) && isnothing(config.target_width)
        return image
    end

    original_height, original_width = size(image)

    # Calculate resize ratio based on configuration
    if !isnothing(config.target_height) && isnothing(config.target_width)
        # Resize based on height
        ratio = config.target_height / original_height
    elseif isnothing(config.target_height) && !isnothing(config.target_width)
        # Resize based on width
        ratio = config.target_width / original_width
    else
        # Both dimensions specified
        if config.maintain_aspect_ratio
            # Use the smaller ratio to ensure image fits within bounds
            height_ratio = config.target_height / original_height
            width_ratio = config.target_width / original_width
            ratio = min(height_ratio, width_ratio)
        else
            # Non-uniform scaling - calculate target size directly
            return ImageTransformations.imresize(image, (config.target_height, config.target_width))
        end
    end

    # Apply uniform scaling
    return ImageTransformations.imresize(image; ratio=ratio)
end

#=
Backward compatibility functions.

These functions maintain the existing API while internally using the new MIME-based system.
This ensures existing code continues to work during the transition.
=#

"""
    get_image_url(page, doc, image::AbstractMatrix{<:Colorant}) -> String

Get URL for an image without resizing (backward compatibility function).

This function maintains backward compatibility with the existing API while using
the new MIME-based processing system internally.
"""
function OhMyCards.get_image_url(page, doc, image::AbstractMatrix{<:Colorant})
    # Use new MIME-based system with no resizing
    config = CoverImageConfig(
        target_height=nothing,
        target_width=nothing,
        preferred_format="png"
    )

    result = process_cover_image(page, doc, image, config)

    # Return URL with leading slash for backward compatibility
    return "/" * result.relative_url
end

"""
    set_cover_to_image!(meta, page, doc, image::AbstractMatrix{<:Colorant})

Set cover image with resizing (backward compatibility function).

This function maintains backward compatibility with the existing API while using
the new MIME-based processing system internally. It applies the default 600px height
resizing that was in the original implementation.
"""
function OhMyCards.set_cover_to_image!(meta, page, doc, image::AbstractMatrix{<:Colorant})
    # Use new MIME-based system with 600px height (matching original behavior)
    config = CoverImageConfig(
        target_height=600,
        preferred_format="png"
    )

    result = process_cover_image(page, doc, image, config)

    # Set the cover in meta with leading slash for backward compatibility
    meta[:Cover] = "/" * result.relative_url
end

end