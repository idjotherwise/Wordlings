using Wordlings
using Test

TEST_FILES = [
  "utils.jl"
]

@testset "Wordlings.jl" begin
  for t in TEST_FILES
    @info "Testing $t..."
    path = joinpath(@__DIR__, t)
    @eval @time @testset $t begin
      include($path)
    end
  end
end
