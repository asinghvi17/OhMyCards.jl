# Content Conversion Interface
#
# This module defines the standard interface for converting content (plots, figures, 
# color matrices, etc.) to various image/video formats. The actual implementations
# are provided by extensions for their specific content types.

"""
    convert_to_format(content, mime::MIME, config::CoverImageConfig) -> Vector{UInt8}

Convert content to the specified MIME format.

This is the standard interface that all extensions should implement. Each extension
provides methods for their specific content types (Plots.Plot, Makie.Figure, etc.).

# Arguments
- `content`: The content to convert (plot, figure, color matrix, etc.)
- `mime::MIME`: Target MIME type (e.g., MIME"image/png"())
- `config::CoverImageConfig`: Configuration for conversion (quality, dimensions, etc.)

# Returns
- `Vector{UInt8}`: Raw bytes of the converted image/video

# Throws
- `UnsupportedFormatError`: If the content type doesn't support the requested MIME type
- `ConversionError`: If conversion fails for any reason

# Examples
```julia
# Extensions implement this for their types:
# function convert_to_format(plot::Plots.Plot, ::MIME"image/png", config::CoverImageConfig)
#     # Use Plots.jl's savefig with PNG backend
#     io = IOBuffer()
#     Plots.savefig(plot, io, format=:png)
#     return take!(io)
# end
```

# Notes
- This base implementation throws `UnsupportedFormatError` for all content types
- Extensions must implement specific methods for their content types
- The MIME type dispatch allows natural support for different formats
- Configuration is passed through for quality settings and dimensions
"""
function convert_to_format(content, mime::MIME, config::CoverImageConfig)::Vector{UInt8}
    throw(UnsupportedFormatError(typeof(content), string(mime)))
end

# Custom error message formatting for better user experience
function Base.showerror(io::IO, e::UnsupportedFormatError)
    print(io, "UnsupportedFormatError: Content type $(e.content_type) does not support format $(e.requested_format). ")
    print(io, "Please ensure the appropriate extension is loaded or implement convert_to_format for this type.")
end

function Base.showerror(io::IO, e::ConversionError)
    print(io, "ConversionError: Failed to convert $(e.content_type) to $(e.format). ")
    print(io, "Original error: ")
    Base.showerror(io, e.original_error)
end

function Base.showerror(io::IO, e::PathGenerationError)
    print(io, "PathGenerationError: $(e.reason)")
end