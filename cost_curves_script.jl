using Revise
using JSON3
include("cost_curves.jl")

env = Gurobi.Env()
#set_optimizer_attribute(model, "Method", 1)

#setparam!(env, "Method", 1)
## Initialize main parameters

scenario = "Distributed Energy"
endtime = 24*365
year = 2040
CY_cap = 1984
CY_ts = 2012
VOLL = 8000
ty = 2035

country = "BE00"
curve_dict = Dict()
import_dict = Dict()
export_dict = Dict()

import_levels = -5000:100:5000
# import_levels = -1000:100:1000

##
#m2,soc,production =  optimize_and_retain_intertemporal_decisions_no_DSR(scenario::String,year::Int,CY_cap::Int,CY_ts,endtime,VOLL)
m2,soc,production =  optimize_and_retain_intertemporal_decisions_no_DSR(scenario::String,year::Int,CY_cap::Int,CY_ts,endtime,VOLL,ty)

set_optimizer_attribute(m2, "Method", 1)

open(joinpath("soc_files","soc_$(ty)_$(CY_ts)_$(scenario)_$(endtime).json"), "w") do io
    JSON3.write(io, write_sparse_axis_to_dict(soc))
end


open(joinpath("soc_files","prod_$(ty)_$(CY_ts)_$(scenario)_$(endtime).json"), "w") do io
    JSON3.write(io, write_sparse_axis_to_dict(production))
end


##
soc_dict = JSON3.read(read(joinpath("soc_files","soc_$(ty)_$(CY_ts)_$(scenario)_$(endtime).json"), String))
production_dict = JSON3.read(read(joinpath("soc_files","prod_$(ty)_$(CY_ts)_$(scenario)_$(endtime).json"), String))


#m2 = build_model_for_import_curve_no_DSR_from_dict(0,country,endtime,soc_dict,production_dict,0)
m2 = build_model_for_import_curve_no_DSR_from_dict_ty(0,country,endtime,soc_dict,production_dict,0,ty)

set_optimizer_attribute(m2, "Method", 1)
optimize!(m2)
for import_level in import_levels
    @show(import_level)
    change_import_level!(m2,endtime,import_level)

    optimize!(m2)

    check_production_zero!(m2,country,endtime)
    check_net_import(m2,country,import_level,endtime)
    check_charge_zero(m2,country,endtime)

    import_prices = [JuMP.dual.(m2.ext[:constraints][:demand_met][country,t]) for t in 1:endtime]
    curve_dict[import_level] = import_prices

    import_dict[import_level] = [sum(JuMP.value.(m2.ext[:variables][:import][country,nb,t]) for nb in m2.ext[:sets][:connections][country]) for t in 1:endtime]
    export_dict[import_level] = [sum(JuMP.value.(m2.ext[:variables][:export][country,nb,t]) for nb in m2.ext[:sets][:connections][country]) for t in 1:endtime]
    end

    write_prices(curve_dict,scenario,import_levels,"$(ty)_CY_$(CY_ts)_$(endtime)")
end
JuMP.termination_status(m2)
write_prices(curve_dict,scenario,sort!(collect(keys(curve_dict))),"$(ty)_CY_$(CY_ts)_$(endtime)")

sum([sum(JuMP.value.(m2.ext[:variables][:import][country,nb,t]) - JuMP.value.(m2.ext[:variables][:export][country,nb,t]) for nb in m2.ext[:sets][:connections][country]) for t in 1:endtime])
findmin([sum(JuMP.value.(m2.ext[:variables][:import][country,nb,t]) - JuMP.value.(m2.ext[:variables][:export][country,nb,t]) for nb in m2.ext[:sets][:connections][country]) for t in 1:endtime])


m2.ext[:constraints][:demand_met]["BE00",8441]
JuMP.objective_value(m2)
sum(JuMP.value.(m2.ext[:variables][:load_shedding]))/sum(JuMP.value.(m2.ext[:variables][:production]))

t = 8441
m2.ext[:variables][:charge]
sum([JuMP.value.(m2.ext[:variables][:charge]["BE00",tech,t]) for tech in m2.ext[:sets][:storage_technologies]["BE00"] ])
sum([JuMP.value.(m2.ext[:variables][:production]["BE00",tech,t]) for tech in m2.ext[:sets][:technologies]["BE00"]])
sum([JuMP.value.(m2.ext[:variables][:import]["BE00",nb,t]) for nb in m2.ext[:sets][:connections]["BE00"]] - [JuMP.value.(m2.ext[:variables][:export]["BE00",nb,t]) for nb in m2.ext[:sets][:connections]["BE00"]])
sum([JuMP.value.(m2.ext[:variables][:load_shedding]["BE00",t])])
