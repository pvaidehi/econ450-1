# purpose: set up environment for the project

# Load necessary packages
using Pkg

# List of packages to ensure they are installed
packages = ["DataFrames", "Statistics", "CSV", "PrettyTables", "GLM", "MixedModels"]

# Function to install missing packages
function ensure_packages(packages)
    for pkg in packages
        if !(pkg in keys(Pkg.dependencies()))
            println("Installing package: $pkg")
            Pkg.add(pkg)
        end
    end
end

# Ensure all necessary packages are installed
ensure_packages(packages)

# Load the packages
using DataFrames, Statistics, CSV, PrettyTables, GLM, MixedModels
