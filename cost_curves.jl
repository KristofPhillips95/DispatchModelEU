include("model_builder.jl")
using Gurobi
using Plots

scenario = "National Trends"
endtime = 24*20
year = 2040
CY = 1984
VOLL = 1000
CO2_price = 0.084

m = Model(optimizer_with_attributes(Gurobi.Optimizer))
define_sets!(m,scenario,year,CY)
process_parameters!(m,scenario,year,CY)
process_time_series!(m,scenario)
build_NTC_model_DSR_shift!(m,endtime,VOLL,CO2_price,VOLL/10,0.25,VOLL/2)
optimize!(m)
soc_1 = JuMP.value.(m.ext[:variables][:soc])
production = JuMP.value.(m.ext[:variables][:production])
DSR_up = JuMP.value.(m.ext[:variables][:DSR_up])
DSR_down = JuMP.value.(m.ext[:variables][:DSR_down])


m2 = Model(optimizer_with_attributes(Gurobi.Optimizer))
define_sets!(m2,scenario,year,CY)
process_parameters!(m2,scenario,year,CY)
process_time_series!(m2,scenario)
remove_capacity_country(m2,"BE00")
set_demand_country(m2,"BE00",1000)
build_NTC_model_DSR_shift!(m2,endtime,VOLL,CO2_price,VOLL/10,0.25,VOLL/2)
fix_soc_decisions(m2,soc_1,production,1:endtime,"BE00")
fix_DSR_decisions(m2,DSR_up,DSR_down,1:endtime,"BE00")
optimize!(m2)
m2.ext[:constraints][:demand_met]["BE00",1]
set_normalized_rhs(m2.ext[:constraints][:demand_met]["BE00",1],1500)
country = "DE00"
plot([sum(JuMP.value.(m.ext[:variables][:soc][country,tech,t] for tech in m.ext[:sets][:soc_technologies][country])) for t in 1:endtime])
plot!([sum(JuMP.value.(m2.ext[:variables][:soc][country,tech,t] for tech in m2.ext[:sets][:soc_technologies][country])) for t in 1:endtime])

plot([sum(JuMP.value.(m.ext[:variables][:production][country,tech,t] for tech in m.ext[:sets][:soc_technologies][country])) for t in 1:endtime])
plot!([sum(JuMP.value.(m2.ext[:variables][:production][country,tech,t] for tech in m2.ext[:sets][:soc_technologies][country])) for t in 1:endtime])

plot([sum(JuMP.value.(m.ext[:variables][:DSR_up][country,t] )) for t in 1:endtime])
plot!([sum(JuMP.value.(m2.ext[:variables][:DSR_up][country,t] )) for t in 1:endtime])
[sum(JuMP.value.(m.ext[:variables][:DSR_up][country,t] )) for t in 1:endtime] == [sum(JuMP.value.(m2.ext[:variables][:DSR_up][country,t] )) for t in 1:endtime]

country = "BE00"
plot([JuMP.dual.(m.ext[:constraints][:demand_met][country,t]) for t in 1:endtime],right_margin = 18Plots.mm,label = "Price")
plot!([JuMP.dual.(m2.ext[:constraints][:demand_met][country,t]) for t in 1:endtime],right_margin = 18Plots.mm,label = "Price")

JuMP.value.(m.ext[:variables][:production]["BE"])
[sum(JuMP.value.(m2.ext[:variables][:import][country,nb,t] ) for nb in m.ext[:sets][:connections][country]) for t in 1:endtime]
- [sum(JuMP.value.(m2.ext[:variables][:export][country,nb,t] ) for nb in m.ext[:sets][:connections][country]) for t in 1:endtime]
##
function optimize_and_retain_intertemporal_decisions(scenario::String,year::Int,CY::Int,endtime,VOLL,CO2_price,sheddable_fraction)
    m = Model(optimizer_with_attributes(Gurobi.Optimizer))
    define_sets!(m,scenario,year,CY)
    process_parameters!(m,scenario,year,CY)
    process_time_series!(m,scenario)
    build_NTC_model_DSR_shift!(m,endtime,VOLL,CO2_price,VOLL/10,sheddable_fraction,VOLL/2)
    optimize!(m)
    soc = JuMP.value.(m.ext[:variables][:soc])
    production = JuMP.value.(m.ext[:variables][:production])
    DSR_up = JuMP.value.(m.ext[:variables][:DSR_up])
    DSR_down = JuMP.value.(m.ext[:variables][:DSR_down])

    return m,soc,production,DSR_up,DSR_down
end

function build_model_for_import_curve(import_level,country,scenario::String,year::Int,CY::Int,endtime,VOLL,CO2_price,sheddable_fraction,soc,production,DSR_up,DSR_down)
    m2 = Model(optimizer_with_attributes(Gurobi.Optimizer))
    define_sets!(m2,scenario,year,CY)
    process_parameters!(m2,scenario,year,CY)
    process_time_series!(m2,scenario)
    remove_capacity_country(m2,country)
    set_demand_country(m2,country,import_level)
    build_NTC_model_DSR_shift!(m2,endtime,VOLL,CO2_price,VOLL/10,sheddable_fraction,VOLL/2)
    fix_soc_decisions(m2,soc,production,1:endtime,country)
    fix_DSR_decisions(m2,DSR_up,DSR_down,1:endtime,country)
    optimize!(m2)
    return m2
end



function check_convexitiy_of_prices(curve_dict, import_levels)
    levels = collect(import_levels)
    sort!(levels)
    for i in 1:length(levels)-1
        print(i)
        println(import_levels[i])
        p_low = round.(curve_dict[import_levels[i]],digits=5)
        p_high = round.(curve_dict[import_levels[i+1]],digits=5)
        bit_array = p_low .<= p_high
        @assert(sum(bit_array) == length(bit_array))
    end
end

function price_duration_curve(prices)
    levels = Set(prices)
    levels = sort(collect(levels))
    #levels = 0:10:250
    price_count_dict = Dict(level => count(x-> x >=level, prices) for level in levels)
    return price_count_dict
end
##

#Start by performing overall optimization

scenario = "Distributed Energy"
endtime = 24*60
year = 2040
CY = 1984
VOLL = 1000
CO2_price = 0.085
sheddable_fraction = 0.25
country = "BE00"
curve_dict = Dict()
import_dict = Dict()
export_dict = Dict()

import_levels = -5000:100:5000
first = true


m, soc, production, DSR_up, DSR_down = optimize_and_retain_intertemporal_decisions(scenario::String,year::Int,CY::Int,endtime,VOLL,CO2_price,sheddable_fraction)

for import_level in i
    mport_levels
    if first
        m2 = build_model_for_import_curve(import_level,country,scenario::String,year::Int,CY::Int,endtime,VOLL,CO2_price,sheddable_fraction,soc,production,DSR_up,DSR_down)
        first = false
    else
        for t in 1:endtime
            set_normalized_rhs(m2.ext[:constraints][:demand_met][country,t],import_level)
        end
        optimize!(m2)
    end
    import_prices = [JuMP.dual.(m2.ext[:constraints][:demand_met][country,t]) for t in 1:endtime]
    curve_dict[import_level] = import_prices

    import_dict[import_level] = [sum(JuMP.value.(m2.ext[:variables][:import][country,nb,t]) for nb in m.ext[:sets][:connections][country]) for t in 1:endtime]
    export_dict[import_level] = [sum(JuMP.value.(m2.ext[:variables][:export][country,nb,t]) for nb in m.ext[:sets][:connections][country]) for t in 1:endtime]
end
plot()
for import_level in import_levels
    plot!(curve_dict[import_level],label = import_level)
end
plot!()

check_convexitiy_of_prices(curve_dict,import_levels)

import_level = 2500
import_dict[import_level] - export_dict[import_level]


##
collect(import_levels)
t=750
pd[500]
pd = Dict( import_level => curve_dict[import_level][t] for import_level in import_levels)
scatter(pd)

scatter(price_duration_curve(curve_dict[1500]))
price_duration_curve(curve_dict[1500])
histogram(curve_dict[500],bins = 500)
histogram(curve_dict[1500],bins = 500)
histogram(curve_dict[2500],bins = 500)
histogram(curve_dict[3500],bins = 500)
##
df_prices = DataFrame()

for price in keys(curve_dict)
    insertcols!(df_prices,1,string(price) => curve_dict[price])
end
insertcols!(df_prices,1,"500" => curve_dict[500])
df_prices[!,500] = curve_dict[500]
CSV.write("Results\\import_price_curves.csv",df_prices)
##
m.hext[:variables]
sum(JuMP.value.(m.ext[:variables][:DSR_up]))
sum(JuMP.value.(m.ext[:variables][:DSR_down]))
sum(JuMP.value.(m.ext[:variables][:DSR_shed]))
sum(JuMP.value.(m.ext[:variables][:load_shedding]))/
    sum(JuMP.value.(m.ext[:variables][:production]))
