#=
High-level orchestrating function for the complete cover image processing pipeline.

This module provides a simple function that coordinates all the components:
- Format detection
- Content conversion
- Path generation and file writing
- HTML generation
=#

using Documenter

"""
    process_cover_image(page, doc, content, config::CoverImageConfig; 
                       extension::Union{String,Nothing}=nothing) -> CoverImageResult

Process content into a cover image through the complete pipeline.

This function orchestrates the entire cover image processing workflow:
1. Determines the output format (from extension or config)
2. Converts content to bytes using the appropriate converter
3. Generates a filename and writes the file to disk
4. Creates HTML embedding code
5. Returns a CoverImageResult with all artifacts

# Arguments
- `page`: Documenter page object
- `doc`: Documenter document object
- `content`: The content to process (plot, figure, image matrix, etc.)
- `config::CoverImageConfig`: Configuration for processing
- `extension::Union{String,Nothing}`: Optional file extension override (e.g., "png", "svg")

# Returns
- `CoverImageResult`: Contains file path, URL, MIME type, HTML, and metadata

# Examples
```julia
config = CoverImageConfig(target_height=800, preferred_format="png")
result = process_cover_image(page, doc, my_plot, config)

# Access the generated artifacts
println(result.file_path)      # "/path/to/build/abc123.png"
println(result.relative_url)   # "examples/abc123.png"
println(result.html_embed)     # "<img src=\"examples/abc123.png\" alt=\"\" />"
```

# Throws
- `UnsupportedFormatError`: If the content type doesn't support the requested format
- `ConversionError`: If conversion fails
- `PathGenerationError`: If file writing fails
"""
function process_cover_image(page, doc, content, config::CoverImageConfig;
    extension::Union{String,Nothing}=nothing)
    # Step 1: Determine the output format
    # Priority: explicit extension > config.preferred_format > fallback
    if !isnothing(extension)
        # Use provided extension
        mime = detect_format_with_fallback("dummy.$extension")
        ext = extension
    elseif !isnothing(config.preferred_format)
        # Use configured preferred format
        mime = detect_format_with_fallback("dummy.$(config.preferred_format)")
        ext = config.preferred_format
    else
        # Use fallback format
        mime = detect_format_with_fallback("dummy.$(config.fallback_format)")
        ext = config.fallback_format
    end

    # Step 2: Convert content to bytes
    # This will dispatch to the appropriate extension-specific converter
    content_bytes = convert_to_format(content, mime, config)

    # Step 3: Generate filename and write file
    # This handles path generation based on Documenter config (prettyurls, etc.)
    filesystem_path, relative_url = generate_and_write_image(
        page, doc, content_bytes, ext,
        prefix=config.filename_prefix
    )

    # Step 4: Generate HTML embedding code
    html = embeddable_html(mime, relative_url, config)

    # Step 5: Create and return result
    metadata = Dict{Symbol,Any}(
        :source_type => typeof(content),
        :format => string(mime),
        :file_size => length(content_bytes)
    )

    return CoverImageResult(
        filesystem_path,
        relative_url,
        mime,
        html,
        metadata
    )
end

"""
    process_cover_image(page, doc, content; kwargs...) -> CoverImageResult

Convenience method that uses default configuration.

# Arguments
- `page`: Documenter page object
- `doc`: Documenter document object  
- `content`: The content to process
- `kwargs...`: Optional keyword arguments passed to CoverImageConfig

# Examples
```julia
# Use all defaults
result = process_cover_image(page, doc, my_plot)

# Override specific config options
result = process_cover_image(page, doc, my_plot, target_height=800, preferred_format="svg")
```
"""
function process_cover_image(page, doc, content; kwargs...)
    config = CoverImageConfig(; kwargs...)
    return process_cover_image(page, doc, content, config)
end
