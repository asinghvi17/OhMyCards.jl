using OhMyCards
using Test

@testset "OhMyCards.jl" begin
    include("test_types.jl")
    include("test_format_detection.jl")
    include("test_html_embedding.jl")
    include("test_content_conversion.jl")
    include("test_path_generation.jl")
    include("test_processor.jl")
    include("test_end_to_end.jl")
    include("test_colors_ext.jl")
    include("test_plots_ext.jl")
    include("test_makie_ext.jl")
    include("test_cardmeta_integration.jl")
end
