# purpose: Set up the environment for the project

# load necessary package manager
using Pkg

# list of required packages
packages = [
    "DataFrames", "Statistics", "CSV", "PrettyTables", "GLM", "MixedModels", 
    "Polynomials", "LinearAlgebra", "Plots", "PlotlyJS", "DataFramesMeta", 
    "FixedEffectModels", "Zygote", "Distributions"
]

# function to ensure all required packages are installed
function ensure_packages(packages)
    for pkg in packages
        if !haskey(Pkg.dependencies(), pkg)
            println("Installing package: $pkg")
            Pkg.add(pkg)
        end
    end
end

ensure_packages(packages)
using DataFrames, Statistics, CSV, PrettyTables, GLM, MixedModels, Polynomials, 
      LinearAlgebra, Plots, PlotlyJS, DataFramesMeta, FixedEffectModels, Zygote,
        Distributions