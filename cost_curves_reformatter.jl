##
function price_duration_curve(prices)
    levels = Set(prices)
    levels = sort(collect(levels))
    #levels = 0:10:250
    price_count_dict = Dict(level => count(x-> x >=level, prices) for level in levels)
    return price_count_dict,levels
end
##
include("Model_builder.jl")
using CSV
using DataFrames
using Plots

year = 2040
endtime = 24*365
CY_ts = 2012

scenario = "Distributed Energy"
##


df = CSV.read("Results\\import_price_curves$(scenario)_$(year)_CY_$(CY_ts)_$(endtime).csv",DataFrame)

prices = df[:,"5000"]
pdc,levels = price_duration_curve(prices)
price_levels = sort(collect(keys(pdc)),rev = true)


import_levels = string.(0:100:5000)
lvls_int = parse.(Int64,names(df))

lvls_int
dict_levels = Dict()
for level in price_levels
    println(level)
    import_pot_a = []
    for ts in 1:8760
        p_ts = df[ts,1:51]
        p_ts_a = Array(p_ts)
        index_max = findfirst(x-> x == level, p_ts_a)
        index_min = findlast(x-> x == level, p_ts_a)
        if index_min == index_max == nothing
            append!(import_pot_a,0)
        else
            # @show(index_min)
            # @show(index_max)
            import_pot = (lvls_int[index_max] + lvls_int[max(1,index_max-1)])/2   - (lvls_int[index_min]+ lvls_int[min(51,index_min+1)])/2
            append!(import_pot_a,import_pot)
        end
    end
    dict_levels[string(level)] = import_pot_a
end
df_levels
df_levels = DataFrame(dict_levels)
CSV.write("Results\\Reformatted_results\\df_price_level_availability$(year)_$(CY_ts)_$(scenario)_$(endtime).csv",df_levels)



plot(df[:,"5000"])

p_ts[p_ts.1 .==p_ts["0"]]

parse(Int64,"0")
Array(p_ts)
