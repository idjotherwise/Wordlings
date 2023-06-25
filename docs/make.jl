using Wordlings
using Documenter

DocMeta.setdocmeta!(Wordlings, :DocTestSetup, :(using Wordlings); recursive=true)

makedocs(;
    modules=[Wordlings, Embed, Utils],
    authors="idjotherwise <ifan.johnston@gmail.com> and contributors",
    repo="https://github.com/idjotherwise/Wordlings.jl/blob/{commit}{path}#{line}",
    sitename="Wordlings.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://idjotherwise.github.io/Wordlings.jl",
        edit_link="main",
        assets=String[]
    ),
    pages=[
        "Home" => "index.md",
    ]
)

deploydocs(;
    repo="github.com/idjotherwise/Wordlings.jl",
    devbranch="main"
)
