using BlankLocalizationCore
using Documenter

DocMeta.setdocmeta!(BlankLocalizationCore, :DocTestSetup, :(using BlankLocalizationCore); recursive=true)

makedocs(;
    modules=[BlankLocalizationCore],
    authors="Tamás Cserteg <cserteg.tamas@sztaki.hu>, András Kovács <akovacs@sztaki.hu> and contributors",
    repo=Remotes.GitHub("cserteGT3", "BlankLocalizationCore.jl"),
    sitename="BlankLocalizationCore.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cserteGT3.github.io/BlankLocalizationCore.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Short 2D example" => "example-2d.md",
        "Complex 3D example" => "example.md",
        "API extension" => "api.md",
        "Reference" => "reference.md"
    ],
)

deploydocs(;
    repo="github.com/cserteGT3/BlankLocalizationCore.jl",
    devbranch="main",
    push_preview = true
)
