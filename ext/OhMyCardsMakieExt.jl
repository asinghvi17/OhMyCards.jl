module OhMyCardsMakieExt

using Makie
import ImageTransformations
import Makie: FileIO, ImageIO
import Documenter

import OhMyCards

# Import the new MIME-based system components
import OhMyCards: convert_to_format, CoverImageConfig, ConversionError, process_cover_image

# Import backward compatibility functions
import OhMyCards: get_image_url, set_cover_to_image!

#=
MIME-based conversion implementations for Makie.jl objects.

These methods implement the convert_to_format interface for Makie.FigureLike types
with support for PNG, SVG, and other formats supported by Makie.jl.
=#

"""
    convert_to_format(fig::Makie.FigureLike, ::MIME"image/png", config::CoverImageConfig) -> Vector{UInt8}

Convert a Makie figure to PNG format.

# Arguments
- `fig`: Makie.FigureLike object (Figure, Scene, etc.) to convert
- `mime`: PNG MIME type
- `config`: Configuration (dimensions are applied via resizing the colorbuffer)

# Returns
- `Vector{UInt8}`: Raw PNG bytes

# Throws
- `ConversionError`: If conversion fails
"""
function OhMyCards.convert_to_format(fig::Makie.FigureLike, ::MIME"image/png", config::CoverImageConfig)::Vector{UInt8}
    try
        # Get the color buffer from the Makie figure
        img = Makie.colorbuffer(fig)
        
        # Apply dimensions if configured
        img_resized = apply_dimensions(img, config)
        
        # Convert to PNG bytes using ImageIO
        iob = IOBuffer()
        ImageIO.save(FileIO.Stream{FileIO.format"PNG"}(iob), img_resized)
        return take!(iob)
    catch e
        throw(ConversionError(typeof(fig), "image/png", e))
    end
end

"""
    convert_to_format(fig::Makie.FigureLike, ::MIME"image/svg+xml", config::CoverImageConfig) -> Vector{UInt8}

Convert a Makie figure to SVG format.

# Arguments
- `fig`: Makie.FigureLike object to convert
- `mime`: SVG MIME type
- `config`: Configuration (dimensions can be applied via Makie's size parameter)

# Returns
- `Vector{UInt8}`: Raw SVG bytes

# Throws
- `ConversionError`: If conversion fails

# Notes
- SVG export preserves vector graphics when possible
- Dimensions from config are applied to the figure before export
"""
function OhMyCards.convert_to_format(fig::Makie.FigureLike, ::MIME"image/svg+xml", config::CoverImageConfig)::Vector{UInt8}
    try
        # Apply dimensions if configured by updating figure size
        fig_to_save = apply_figure_dimensions(fig, config)
        
        # For SVG, we need to use a temporary file because Makie's save
        # doesn't work properly with IOBuffer streams for vector formats
        mktempdir() do tmpdir
            tmpfile = joinpath(tmpdir, "temp.svg")
            Makie.save(tmpfile, fig_to_save)
            return read(tmpfile)
        end
    catch e
        throw(ConversionError(typeof(fig), "image/svg+xml", e))
    end
end

"""
    convert_to_format(fig::Makie.FigureLike, ::MIME"application/pdf", config::CoverImageConfig) -> Vector{UInt8}

Convert a Makie figure to PDF format.

# Arguments
- `fig`: Makie.FigureLike object to convert
- `mime`: PDF MIME type
- `config`: Configuration (dimensions can be applied via Makie's size parameter)

# Returns
- `Vector{UInt8}`: Raw PDF bytes

# Throws
- `ConversionError`: If conversion fails
"""
function OhMyCards.convert_to_format(fig::Makie.FigureLike, ::MIME"application/pdf", config::CoverImageConfig)::Vector{UInt8}
    try
        # Apply dimensions if configured
        fig_to_save = apply_figure_dimensions(fig, config)
        
        # For PDF, we need to use a temporary file
        mktempdir() do tmpdir
            tmpfile = joinpath(tmpdir, "temp.pdf")
            Makie.save(tmpfile, fig_to_save)
            return read(tmpfile)
        end
    catch e
        throw(ConversionError(typeof(fig), "application/pdf", e))
    end
end

"""
    apply_dimensions(img::AbstractMatrix, config::CoverImageConfig) -> AbstractMatrix

Apply dimension configuration to an image matrix by resizing.

# Arguments
- `img`: Original image matrix (from Makie.colorbuffer)
- `config`: Configuration with target dimensions

# Returns
- Resized image matrix (or original if no dimensions configured)
"""
function apply_dimensions(img::AbstractMatrix, config::CoverImageConfig)
    # If no dimensions specified, return original image
    if isnothing(config.target_height) && isnothing(config.target_width)
        return img
    end
    
    # Get current image size (height, width)
    current_height, current_width = size(img)
    
    # Calculate resize ratio based on configuration
    if !isnothing(config.target_height) && isnothing(config.target_width)
        # Resize based on height, maintaining aspect ratio
        ratio = config.target_height / current_height
    elseif isnothing(config.target_height) && !isnothing(config.target_width)
        # Resize based on width, maintaining aspect ratio
        ratio = config.target_width / current_width
    else
        # Both dimensions specified
        if config.maintain_aspect_ratio
            # Use the smaller ratio to ensure image fits within bounds
            height_ratio = config.target_height / current_height
            width_ratio = config.target_width / current_width
            ratio = min(height_ratio, width_ratio)
        else
            # Non-uniform scaling - calculate target size directly
            new_height = config.target_height
            new_width = config.target_width
            return ImageTransformations.imresize(img, (new_height, new_width))
        end
    end
    
    # Apply uniform scaling
    return ImageTransformations.imresize(img; ratio=ratio)
end

"""
    apply_figure_dimensions(fig::Makie.FigureLike, config::CoverImageConfig) -> Makie.FigureLike

Apply dimension configuration to a Makie figure.

For vector formats (SVG, PDF), dimensions are applied by updating the figure's resolution
rather than resizing the raster output.

# Arguments
- `fig`: Original Makie figure
- `config`: Configuration with target dimensions

# Returns
- Figure with updated dimensions (or original if no dimensions configured)

# Notes
- For Makie, we update the figure's resolution attribute if possible
- If the figure doesn't support direct size modification, returns original
"""
function apply_figure_dimensions(fig::Makie.FigureLike, config::CoverImageConfig)
    # If no dimensions specified, return original figure
    if isnothing(config.target_height) && isnothing(config.target_width)
        return fig
    end
    
    # For Makie figures, we can try to update the resolution
    # This is best-effort - if it fails, we return the original figure
    try
        # Get current figure size
        current_size = Makie.size(fig)
        current_width, current_height = current_size
        
        # Calculate new dimensions based on configuration
        if !isnothing(config.target_height) && isnothing(config.target_width)
            # Resize based on height, maintaining aspect ratio
            ratio = config.target_height / current_height
            new_width = round(Int, current_width * ratio)
            new_height = config.target_height
        elseif isnothing(config.target_height) && !isnothing(config.target_width)
            # Resize based on width, maintaining aspect ratio
            ratio = config.target_width / current_width
            new_height = round(Int, current_height * ratio)
            new_width = config.target_width
        else
            # Both dimensions specified
            if config.maintain_aspect_ratio
                # Use the smaller ratio to ensure figure fits within bounds
                height_ratio = config.target_height / current_height
                width_ratio = config.target_width / current_width
                ratio = min(height_ratio, width_ratio)
                new_width = round(Int, current_width * ratio)
                new_height = round(Int, current_height * ratio)
            else
                # Non-uniform scaling - use exact dimensions
                new_width = config.target_width
                new_height = config.target_height
            end
        end
        
        # Try to resize the figure
        Makie.resize!(fig, new_width, new_height)
        return fig
    catch e
        # If resizing fails, log a warning and return original figure
        @debug "Could not resize Makie figure, using original size" exception=e
        return fig
    end
end

#=
Backward compatibility functions.

These functions maintain the existing API while internally using the new MIME-based system.
This ensures existing code continues to work during the transition.
=#

"""
    get_image_url(page, doc, fig::Makie.FigureLike) -> String

Get URL for a Makie figure without resizing (backward compatibility function).

This function maintains backward compatibility with the existing API while using
the new MIME-based processing system internally.
"""
function OhMyCards.get_image_url(page, doc, fig::Makie.FigureLike)
    try
        # Use new MIME-based system with no resizing
        config = CoverImageConfig(
            target_height=nothing,
            target_width=nothing,
            preferred_format="png"
        )
        
        result = process_cover_image(page, doc, fig, config)
        
        # Return URL with leading slash for backward compatibility
        return "/" * result.relative_url
    catch e
        @error "Error while processing Makie figure" page=page.source exception=e
        # Fallback: create a red error pixel
        error_img = reshape([Makie.RGBf(1, 0, 0)], 1, 1)
        iob = IOBuffer()
        ImageIO.save(FileIO.Stream{FileIO.format"PNG"}(iob), error_img)
        bytes = take!(iob)
        filename = string(hash(bytes), base=62) * ".png"
        path = joinpath(page.workdir, filename)
        write(path, bytes)
        return "/" * joinpath(relpath(page.workdir, doc.user.build), filename)
    end
end

"""
    set_cover_to_image!(meta, page, doc, fig::Makie.FigureLike)

Set cover image with resizing (backward compatibility function).

This function maintains backward compatibility with the existing API while using
the new MIME-based processing system internally. It applies the default 600px height
resizing that was in the original implementation.
"""
function OhMyCards.set_cover_to_image!(meta, page, doc, fig::Makie.FigureLike)
    try
        # Use new MIME-based system with 600px height (matching original behavior)
        config = CoverImageConfig(
            target_height=600,
            preferred_format="png"
        )
        
        result = process_cover_image(page, doc, fig, config)
        
        # Set the cover in meta with leading slash for backward compatibility
        meta[:Cover] = "/" * result.relative_url
    catch e
        @error "Error while processing Makie figure for cover" page=page.source exception=e
        rethrow(e)
    end
end

end
