module OhMyCardsMakieExt
using Makie

import ImageTransformations
import Makie: FileIO, ImageIO
import Documenter

import OhMyCards
import OhMyCards: get_image_url, set_cover_to_image!


function OhMyCards.get_image_url(page, doc, fig::Makie.FigureLike)
    img = try
        Makie.colorbuffer(fig)
    catch e
        @error "Error while saving Makie figure in the card!" page=page.source 
        @error e
        reshape([Makie.RGBf(1, 0, 0)], 1, 1)
    end
    iob = IOBuffer()
    ImageIO.save(FileIO.Stream{FileIO.format"PNG"}(iob), img)
    # We could include this inline, but that seems to be causing issues.
    # meta[:Cover] = "data:image/png;base64, " * Base64.base64encode(String(take!(iob)))
    # Instead, we will save to a file and include that.
    bytes = take!(iob)
    filename = string(hash(bytes), base = 62) * ".png"
    path = joinpath(page.workdir, filename)
    write(path, bytes)
    return joinpath(relpath(page.workdir, doc.user.build), filename)
end

function OhMyCards.set_cover_to_image!(meta, page, doc, fig::Makie.FigureLike)
    # convert figure to image
    original_cover_image = try
        Makie.colorbuffer(meta[:Cover])
    catch e
        @error "Error while saving Makie figure in the card!" page=page.source 
        rethrow(e)
    end
    
    ratio = 600 / size(original_cover_image, 1) # get 300px height
    resized_cover_image = ImageTransformations.imresize(original_cover_image; ratio)
    
    # Below is the "inline pipeline"
    iob = IOBuffer()
    ImageIO.save(FileIO.Stream{FileIO.format"PNG"}(iob), resized_cover_image)
    # We could include this inline, but that seems to be causing issues.
    # meta[:Cover] = "data:image/png;base64, " * Base64.base64encode(String(take!(iob)))
    # Instead, we will save to a file and include that.
    bytes = take!(iob)
    filename = string(hash(bytes), base = 62) * ".png"
    write(joinpath(page.workdir, filename), bytes)
    html_idx = findfirst(x -> x isa Documenter.HTML, doc.user.format)
    has_prettyurls = if isnothing(html_idx)
        false
    else
        doc.user.format[html_idx].prettyurls
    end

    meta[:Cover] = if has_prettyurls
        normpath(joinpath(relpath(page.workdir, doc.user.build), splitext(last(splitpath(page.source)))[1], filename))
    else
        normpath(joinpath(relpath(page.workdir, doc.user.build), filename))
    end
end

end
