# define completely interacted polynomial functions with three vairables
function poly(x::Symbol, y::Symbol, z::Symbol, data::DataFrame; degree::Int)
    poly_data = DataFrame()
    poly_data[!, x] = data[!, x]
    poly_data[!, y] = data[!, y]
    poly_data[!, z] = data[!, z]
    # Add each polynomial term to the new DataFrame
    for (i, j, k) in Iterators.product(0:degree, 0:degree, 0:degree)
        if i + j + k <= degree && (i > 0 || j > 0 || k > 0)
            term_name = Symbol("term_$(i)_$(j)_$(k)")
            poly_data[!, term_name] = data[!, x].^i .* data[!, y].^j .* data[!, z].^k
        end
    end
    return poly_data
end

# bootstrap
function bstrap(data::DataFrame, fun, reps::Int)
    coefs = Vector{Any}() 
    for i in 1:reps
        # resample the data with replacement using firm_id
        sampled_data = DataFrame()
        for firm_id in unique(data.firm_id)
            firm_data = data[data.firm_id .== firm_id, :]
            sampled_firm_data = sample(firm_data, replace=true, n=length(firm_data))
            append!(sampled_data, sampled_firm_data)
        end
        result = fun(sampled_data)
        push!(coefs, result) 
    end
    return coefs
end