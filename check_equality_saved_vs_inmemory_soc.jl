using Revise
using JSON3
include("cost_curves.jl")

env = Gurobi.Env()
#set_optimizer_attribute(model, "Method", 1)

#setparam!(env, "Method", 1)
## Initialize main parameters

scenario = "Distributed Energy"
endtime = 24*10
year = 2040
CY_cap = 1984
CY_ts = 2012
VOLL = 8000

country = "BE00"
curve_dict = Dict()
import_dict = Dict()
export_dict = Dict()

import_levels = -5000:100:5000
import_levels = -1000:100:1000

##

m2,soc,production =  optimize_and_retain_intertemporal_decisions_no_DSR(scenario::String,year::Int,CY_cap::Int,CY_ts,endtime,VOLL)

open(joinpath("soc_files","soc_$(year)_$(CY_ts)_$(scenario)_$(endtime).json"), "w") do io
    JSON3.write(io, write_sparse_axis_to_dict(soc))
end


open(joinpath("soc_files","prod_$(year)_$(CY_ts)_$(scenario)_$(endtime).json"), "w") do io
    JSON3.write(io, write_sparse_axis_to_dict(production))
end



# And
m2 = build_model_for_import_curve_no_DSR(m2,0,country,endtime,soc,production,0)


soc_dict = JSON3.read(read(joinpath("soc_files","soc_$(year)_$(CY_ts)_$(scenario)_$(endtime).json"), String))
production_dict = JSON3.read(read(joinpath("soc_files","prod_$(year)_$(CY_ts)_$(scenario)_$(endtime).json"), String))


m3 = build_model_for_import_curve_no_DSR_from_dict(0,country,endtime,soc_dict,production_dict,0)

net_import = [sum(JuMP.value.(m2.ext[:variables][:import][country,nb,t]) - JuMP.value.(m2.ext[:variables][:export][country,nb,t]) for nb in m2.ext[:sets][:connections][country]) for t in 1:endtime]

for import_level in import_levels
    change_import_level!(m2,endtime,import_level)
    change_import_level!(m3,endtime,import_level)

    optimize!(m2)
    optimize!(m3)

    check_production_zero!(m2,country,endtime)
    check_net_import(m2,country,import_level,endtime)

    check_production_zero!(m3,country,endtime)
    check_net_import(m3,country,import_level,endtime)

    check_equal_soc_for_all_but(m3,m2,country,endtime)
    println(JuMP.objective_value(m2))
    println(JuMP.objective_value(m3) - JuMP.objective_value(m2))
    @assert(round(JuMP.objective_value(m2),digits = 0) == round(JuMP.objective_value(m3),digits = 0))

    import_prices = [JuMP.dual.(m2.ext[:constraints][:demand_met][country,t]) for t in 1:endtime]
    curve_dict[import_level] = import_prices

    import_dict[import_level] = [sum(JuMP.value.(m2.ext[:variables][:import][country,nb,t]) for nb in m2.ext[:sets][:connections][country]) for t in 1:endtime]
    export_dict[import_level] = [sum(JuMP.value.(m2.ext[:variables][:export][country,nb,t]) for nb in m2.ext[:sets][:connections][country]) for t in 1:endtime]
    end

    write_prices(curve_dict,scenario,import_levels,"$(year)_CY_$(CY_ts)_$(endtime)")
end
