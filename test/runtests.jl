using OhMyCards
using Test

@testset "OhMyCards.jl" begin
    # Write your tests here.
    include("test_renderers.jl")
    include("test_overview_build.jl")
end
