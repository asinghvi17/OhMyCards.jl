module OhMyCardsPlotsExt

using Plots
import OhMyCards

# Import the new MIME-based system components
import OhMyCards: convert_to_format, CoverImageConfig, process_cover_image

# Import backward compatibility functions
import OhMyCards: get_image_url, set_cover_to_image!

#=
MIME-based conversion implementations for Plots.jl objects.

These methods implement the convert_to_format interface for Plots.Plot and Plots.Subplot
with support for PNG, SVG, and other formats supported by Plots.jl.
=#

"""
    convert_to_format(plot::Union{Plots.Plot, Plots.Subplot}, ::MIME"image/png", config::CoverImageConfig) -> Vector{UInt8}

Convert a Plots.jl plot to PNG format.

# Arguments
- `plot`: Plots.Plot or Plots.Subplot to convert
- `mime`: PNG MIME type
- `config`: Configuration (dimensions can be applied via Plots size parameter)

# Returns
- `Vector{UInt8}`: Raw PNG bytes
"""
function OhMyCards.convert_to_format(plot::Union{Plots.Plot, Plots.Subplot}, ::MIME"image/png", config::CoverImageConfig)::Vector{UInt8}
    # Apply dimensions if configured
    plot_to_save = apply_dimensions(plot, config)
    
    # Convert to PNG bytes using Plots.jl's png function
    iob = IOBuffer()
    Plots.png(plot_to_save, iob)
    return take!(iob)
end

"""
    convert_to_format(plot::Union{Plots.Plot, Plots.Subplot}, ::MIME"image/svg+xml", config::CoverImageConfig) -> Vector{UInt8}

Convert a Plots.jl plot to SVG format.

# Arguments
- `plot`: Plots.Plot or Plots.Subplot to convert
- `mime`: SVG MIME type
- `config`: Configuration (dimensions can be applied via Plots size parameter)

# Returns
- `Vector{UInt8}`: Raw SVG bytes
"""
function OhMyCards.convert_to_format(plot::Union{Plots.Plot, Plots.Subplot}, ::MIME"image/svg+xml", config::CoverImageConfig)::Vector{UInt8}
    # Apply dimensions if configured
    plot_to_save = apply_dimensions(plot, config)
    
    # Convert to SVG bytes using Plots.jl's svg function
    iob = IOBuffer()
    Plots.svg(plot_to_save, iob)
    return take!(iob)
end

"""
    convert_to_format(plot::Union{Plots.Plot, Plots.Subplot}, ::MIME"application/pdf", config::CoverImageConfig) -> Vector{UInt8}

Convert a Plots.jl plot to PDF format.

# Arguments
- `plot`: Plots.Plot or Plots.Subplot to convert
- `mime`: PDF MIME type
- `config`: Configuration (dimensions can be applied via Plots size parameter)

# Returns
- `Vector{UInt8}`: Raw PDF bytes
"""
function OhMyCards.convert_to_format(plot::Union{Plots.Plot, Plots.Subplot}, ::MIME"application/pdf", config::CoverImageConfig)::Vector{UInt8}
    # Apply dimensions if configured
    plot_to_save = apply_dimensions(plot, config)
    
    # Convert to PDF bytes using Plots.jl's pdf function
    iob = IOBuffer()
    Plots.pdf(plot_to_save, iob)
    return take!(iob)
end

"""
    apply_dimensions(plot::Union{Plots.Plot, Plots.Subplot}, config::CoverImageConfig) -> Union{Plots.Plot, Plots.Subplot}

Apply dimension configuration to a plot.

For Plots.jl, dimensions are applied by modifying the plot's size attribute.
If no dimensions are configured, returns the original plot.

# Arguments
- `plot`: Original plot
- `config`: Configuration with target dimensions

# Returns
- Plot with updated dimensions (or original if no dimensions configured)
"""
function apply_dimensions(plot::Union{Plots.Plot, Plots.Subplot}, config::CoverImageConfig)
    # If no dimensions specified, return original plot
    if isnothing(config.target_height) && isnothing(config.target_width)
        return plot
    end
    
    # Get current plot size
    current_size = plot[:size]
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
            # Use the smaller ratio to ensure plot fits within bounds
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
    
    # Create a copy of the plot with new size
    # Note: Plots.jl's plot() function with an existing plot creates a modified copy
    return Plots.plot(plot, size=(new_width, new_height))
end

#=
Backward compatibility functions.

These functions maintain the existing API while internally using the new MIME-based system.
This ensures existing code continues to work during the transition.
=#

"""
    get_image_url(page, doc, plot::Union{Plots.Plot, Plots.Subplot}) -> String

Get URL for a plot without resizing (backward compatibility function).

This function maintains backward compatibility with the existing API while using
the new MIME-based processing system internally.
"""
function OhMyCards.get_image_url(page, doc, plot::Union{Plots.Plot, Plots.Subplot})
    # Use new MIME-based system with no resizing
    config = CoverImageConfig(
        target_height=nothing,
        target_width=nothing,
        preferred_format="png"
    )
    
    result = process_cover_image(page, doc, plot, config)
    
    # Return URL with leading slash for backward compatibility
    return "/" * result.relative_url
end

"""
    set_cover_to_image!(meta, page, doc, plot::Union{Plots.Plot, Plots.Subplot})

Set cover image with resizing (backward compatibility function).

This function maintains backward compatibility with the existing API while using
the new MIME-based processing system internally. It applies the default 600px height
resizing that was in the original implementation.
"""
function OhMyCards.set_cover_to_image!(meta, page, doc, plot::Union{Plots.Plot, Plots.Subplot})
    # Use new MIME-based system with 600px height (matching original behavior)
    config = CoverImageConfig(
        target_height=600,
        preferred_format="png"
    )
    
    result = process_cover_image(page, doc, plot, config)
    
    # Set the cover in meta with leading slash for backward compatibility
    meta[:Cover] = "/" * result.relative_url
end

end