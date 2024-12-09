# purpose: set up the environment for the project
# load necessary package manager
using Pkg

# list of required packages
packages = [
    "DataFrames", "Statistics", "CSV", "PrettyTables", "GLM", "MixedModels", 
    "Polynomials", "LinearAlgebra", "Plots", "PlotlyJS", "DataFramesMeta", 
    "FixedEffectModels", "Zygote", "Distributions", "MAT"
]

# function to ensure all required packages are installed
# function ensure_packages(packages)
#     for pkg in packages
#         if !haskey(Pkg.dependencies(), pkg)
#             println("Installing package: $pkg")
#             Pkg.add(pkg)
#         end
#     end
# end

# ensure_packages(packages)
using Random, MAT, Plots, Distributions, LinearAlgebra, Ipopt, JuMP, ForwardDiff
Random.seed!(1234)