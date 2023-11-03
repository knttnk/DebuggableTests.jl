using DebuggableTests
using Documenter

DocMeta.setdocmeta!(DebuggableTests, :DocTestSetup, :(using DebuggableTests); recursive=true)

makedocs(;
    modules=[DebuggableTests],
    authors="knttnk <61683744+knttnk@users.noreply.github.com> and contributors",
    repo="https://github.com/knttnk/DebuggableTests.jl/blob/{commit}{path}#{line}",
    sitename="DebuggableTests.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://knttnk.github.io/DebuggableTests.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/knttnk/DebuggableTests.jl",
    devbranch="main",
)
