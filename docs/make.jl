using BlankLocalizationCore
using Documenter

DocMeta.setdocmeta!(BlankLocalizationCore, :DocTestSetup, :(using BlankLocalizationCore); recursive=true)

makedocs(;
    modules=[BlankLocalizationCore],
    authors="Tamás Cserteg <cserteg.tamas@sztaki.hu>, András Kovács <akovacs@sztaki.hu> and contributors",
    repo="https://github.com/cserteGT3/BlankLocalizationCore.jl/blob/{commit}{path}#{line}",
    sitename="BlankLocalizationCore.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cserteGT3.github.io/BlankLocalizationCore.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Example" => "example.md",
        "API extensions" => "api.md",
        "Reference" => "reference.md"
    ],
)

deploydocs(;
    repo="github.com/cserteGT3/BlankLocalizationCore.jl",
    devbranch="main",
)
