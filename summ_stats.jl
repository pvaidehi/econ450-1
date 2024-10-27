# purpose: part 1 of q2

function generate_stats_and_tables(df, data, variable_names, suffix)
    # summary stats
    summ_stats = DataFrame(
        Variable = String[], 
        Observations = Int[], 
        Mean = Float64[], 
        Median = Float64[],
        Std_Dev = Float64[], 
        P25 = Float64[], 
        P75 = Float64[]
    )

    # loop through variables
    for (var, name) in zip(data, variable_names)

        # Calculate statistics
        observations = length(var)
        mean_value = mean(var)
        median_value = median(var)
        std_dev = std(var)
        p25 = quantile(var, 0.25)
        p75 = quantile(var, 0.75)

        # append stats
        push!(summ_stats, (name, observations, mean_value, median_value, std_dev, p25, p75))
    end

    # export latex table as string
    latex_table = pretty_table(String, summ_stats, 
        header = ["Variable", "Observations", "Mean", "Median", "Std Dev", "25th Percentile", "75th Percentile"],
        backend = Val(:latex))

    # save to file
    open("outputs/summary_stats_table_$suffix.tex", "w") do io
        write(io, latex_table)
    end

    # number of firms per industry-year
    columns_to_sum = [Symbol("X$(i < 10 ? "0$i" : i)") for i in 4:21]
    totals_by_year = combine(groupby(df, :year), 
                            columns_to_sum .=> sum)

    new_names = ["Ind $i" for i in 1:18]
    rename!(totals_by_year, names(totals_by_year)[2:end] .=> new_names)
    table = pretty_table(String, totals_by_year, backend = Val(:latex))
    open("outputs/ind_year_counts_$suffix.tex", "w") do io
        write(io, table)
    end

    # number of firms with zero investment/labour/materials per year
    zero_investment = combine(groupby(df, :year), :X39 => (x -> sum(x .== 0)) => :Zero_Investment)
    zero_labour = combine(groupby(df, :year), :X43 => (x -> sum(x .== 0)) => :Zero_Labour)
    zero_materials = combine(groupby(df, :year), :X44 => (x -> sum(x .== 0)) => :Zero_Materials)

    zeroes = innerjoin(zero_investment, zero_labour, zero_materials, on = :year)
    table = pretty_table(String, zeroes, backend = Val(:latex))
    open("outputs/zeroes_by_year_$suffix.tex", "w") do io
        write(io, table)
    end
end