# MIME-based format detection system for cover images

"""
    MIME_MAPPING

Dictionary mapping file extensions to their corresponding MIME types.
Supports PNG, JPEG, WebP, SVG, GIF, and MP4 formats.
"""
const MIME_MAPPING = Dict{String, MIME}(
    ".png"  => MIME("image/png"),
    ".jpg"  => MIME("image/jpeg"),
    ".jpeg" => MIME("image/jpeg"),
    ".webp" => MIME("image/webp"),
    ".svg"  => MIME("image/svg+xml"),
    ".gif"  => MIME("image/gif"),
    ".mp4"  => MIME("video/mp4")
)

"""
    detect_format(filename::String) -> Union{MIME, Nothing}

Detect the appropriate MIME type based on the file extension.

# Arguments
- `filename::String`: The filename to analyze

# Returns
- `MIME`: The detected MIME type for supported formats
- `nothing`: For unknown/unsupported file extensions

# Examples
```julia
julia> detect_format("image.png")
MIME type image/png

julia> detect_format("video.mp4")
MIME type video/mp4

julia> detect_format("unknown.xyz")
nothing
```
"""
function detect_format(filename::String)::Union{MIME, Nothing}
    # Extract file extension and convert to lowercase
    ext = lowercase(splitext(filename)[2])
    
    # Handle special case where filename starts with dot (like ".png")
    # In this case, splitext treats it as filename, not extension
    if isempty(ext) && startswith(filename, ".")
        ext = lowercase(filename)
    end
    
    # Handle empty extension case
    if isempty(ext)
        return nothing
    end
    
    # Return corresponding MIME type or nothing for unknown extensions
    return get(MIME_MAPPING, ext, nothing)
end

"""
    detect_format_with_fallback(filename::String, fallback::MIME = MIME"image/png"()) -> MIME

Detect the appropriate MIME type based on the file extension, with fallback for unknown extensions.

# Arguments
- `filename::String`: The filename to analyze
- `fallback::MIME`: The MIME type to use for unknown extensions (default: PNG)

# Returns
- `MIME`: The detected MIME type, or the fallback MIME type for unknown extensions

# Examples
```julia
julia> detect_format_with_fallback("image.png")
MIME type image/png

julia> detect_format_with_fallback("unknown.xyz")
MIME type image/png

julia> detect_format_with_fallback("unknown.xyz", MIME"image/jpeg"())
MIME type image/jpeg
```
"""
function detect_format_with_fallback(filename::String, fallback::MIME = MIME("image/png"))
    detected = detect_format(filename)
    return detected === nothing ? fallback : detected
end