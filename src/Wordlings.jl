module Wordlings

using DotEnv
DotEnv.config()
include("./Utils.jl")
include("./Embed.jl")

using Reexport

@reexport using .Utils
@reexport using .Embed

end
