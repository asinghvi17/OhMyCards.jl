#=
Path generation and file management for cover images.

This module provides utilities for:
- Generating content-based filenames using hash functions
- Normalizing paths across platforms and Documenter configurations
- Handling prettyurls and other Documenter settings
- Writing files with proper error handling
=#

using Documenter

"""
    generate_filename(content_bytes::Vector{UInt8}, extension::String; prefix::String="") -> String

Generate a content-based filename using hash of the content bytes.

# Arguments
- `content_bytes`: The raw bytes of the content to hash
- `extension`: File extension (with or without leading dot)
- `prefix`: Optional prefix for the filename (default: "")

# Returns
- String: Filename in format "{prefix}{hash}.{extension}"

# Examples
```julia
bytes = UInt8[1, 2, 3, 4]
generate_filename(bytes, "png")  # "3xqvD.png"
generate_filename(bytes, ".png", prefix="cover_")  # "cover_3xqvD.png"
```
"""
function generate_filename(content_bytes::Vector{UInt8}, extension::String; prefix::String="")
    # Remove leading dot from extension if present
    ext = startswith(extension, ".") ? extension[2:end] : extension
    
    # Generate hash in base 62 for shorter, URL-safe filenames
    hash_str = string(hash(content_bytes), base=62)
    
    # Combine prefix, hash, and extension
    return "$(prefix)$(hash_str).$(ext)"
end

"""
    has_prettyurls(doc) -> Bool

Check if the Documenter configuration has prettyurls enabled.

# Arguments
- `doc`: Documenter document object (or any object with `doc.user.format` structure)

# Returns
- Bool: true if prettyurls is enabled, false otherwise
"""
function has_prettyurls(doc)
    html_idx = findfirst(x -> x isa Documenter.HTML, doc.user.format)
    if isnothing(html_idx)
        return false
    end
    return doc.user.format[html_idx].prettyurls
end

"""
    generate_relative_path(page, doc::Documenter.Document, filename::String) -> String

Generate a relative path for an image file based on Documenter configuration.

When prettyurls is enabled, pages are organized as `page-name/index.html`, so images
need to be referenced relative to that structure. When disabled, pages are `page-name.html`
and images are in the same directory.

# Arguments
- `page`: Documenter page object
- `doc`: Documenter document object
- `filename`: Name of the image file

# Returns
- String: Normalized relative path suitable for HTML embedding (relative to the HTML file location)

# Examples
```julia
# With prettyurls=false:
# page.source = "examples/plot.md" -> "examples/plot.html"
# Image written to: "examples/cover_abc123.png"
# Result: "./cover_abc123.png" (relative to the HTML file)

# With prettyurls=true:
# page.source = "examples/plot.md" -> "examples/plot/index.html"
# Image written to: "examples/cover_abc123.png"
# Result: "../cover_abc123.png" (relative to the HTML file, up one directory)
```
"""
function generate_relative_path(page, doc::Documenter.Document, filename::String)
    if has_prettyurls(doc)
        # With prettyurls, pages are organized as page-name/index.html
        # The image is written to page.workdir (e.g., build/examples/)
        # The HTML file is at page-name/index.html (e.g., build/examples/plot/index.html)
        # So we need to go up one directory: ../filename
        return joinpath("..", filename)
    else
        # Without prettyurls, pages are page-name.html in the same directory as the image
        # Both the HTML file and image are in page.workdir
        # So we just need the filename with ./ prefix for clarity
        return joinpath(".", filename)
    end
end

"""
    write_image_file(filepath::String, content_bytes::Vector{UInt8})

Write image bytes to a file with proper error handling.

Creates parent directories if they don't exist. Logs errors but doesn't throw
to avoid breaking the documentation build process.

# Arguments
- `filepath`: Full path where the file should be written
- `content_bytes`: Raw bytes to write

# Throws
- `PathGenerationError`: If file writing fails
"""
function write_image_file(filepath::String, content_bytes::Vector{UInt8})
    try
        # Ensure parent directory exists
        parent_dir = dirname(filepath)
        if !isempty(parent_dir) && !isdir(parent_dir)
            mkpath(parent_dir)
        end
        
        # Write the file
        write(filepath, content_bytes)
        
        @debug "Successfully wrote image file" filepath size=length(content_bytes)
    catch e
        @error "Failed to write image file" filepath exception=e
        rethrow(e)
    end
end

"""
    generate_and_write_image(page, doc::Documenter.Document, content_bytes::Vector{UInt8}, 
                            extension::String; prefix::String="") -> Tuple{String, String}

Generate filename, write image file, and return both filesystem path and relative URL.

This is a convenience function that combines filename generation, file writing, and
path generation into a single operation.

# Arguments
- `page`: Documenter page object
- `doc`: Documenter document object
- `content_bytes`: Raw image bytes to write
- `extension`: File extension (e.g., "png", "jpg")
- `prefix`: Optional filename prefix (default: "")

# Returns
- Tuple{String, String}: (filesystem_path, relative_url)
  - `filesystem_path`: Absolute path where file was written
  - `relative_url`: Relative path for HTML embedding

# Examples
```julia
bytes = read("image.png")
fs_path, url = generate_and_write_image(page, doc, bytes, "png", prefix="cover_")
# fs_path: "/path/to/build/examples/cover_abc123.png"
# url: "examples/cover_abc123.png" (or "examples/plot/cover_abc123.png" with prettyurls)
```
"""
function generate_and_write_image(page, doc::Documenter.Document, content_bytes::Vector{UInt8}, 
                                 extension::String; prefix::String="")
    # Generate filename based on content hash
    filename = generate_filename(content_bytes, extension; prefix=prefix)
    
    # Generate filesystem path (where to write the file)
    filesystem_path = joinpath(page.workdir, filename)
    
    # Write the file
    write_image_file(filesystem_path, content_bytes)
    
    # Generate relative URL for HTML embedding
    relative_url = generate_relative_path(page, doc, filename)
    
    return (filesystem_path, relative_url)
end
