include("Model_builder.jl")
using CSV
using DataFrames
using Plots

import_level = "5000"



year = 2040
endtime = 24*365
CY_ts = 2012

scenario = "Distributed Energy"
#scenario = "National Trends"


plot()

df = CSV.read("Results\\import_price_curves$(scenario)_$(year)_CY_$(CY_ts)_$(endtime).csv",DataFrame)

prices = df[:,import_level]
pdc,levels = price_duration_curve(prices)
price_levels = sort(collect(keys(pdc)),rev = true)



prices_without_voll = filter(p -> p <7999 , prices)


histogram(prices,bins = 200)

savefig("Results\\Price histogram $(scenario)_$(year)_CY_$(CY_ts)_$(endtime)_$(import_level)")

histogram(prices_without_voll,bins = 200)
price_levels = sort(collect(keys(pdc)),rev = true)

savefig("Results\\Price histogram without voll $(scenario)_$(year)_CY_$(CY_ts)_$(endtime)_$(import_level)")



pdc_array = [pdc[pl] for pl in levels]

plot(pdc_array,levels, ylabel = "Price", xlabel = "Number of hours", title = "Price duration curve import $(import_level) MW")

plot!()
savefig("Results\\Price duration curve$(scenario)_$(year)_CY_$(CY_ts)_$(endtime)_$(import_level)")
##
imp_lvs = ["-5000" "-3000" "-1000" "1000" "3000" "5000"]

year = 2040
endtime = 24*365
CY_ts = 2012

scenario = "Distributed Energy"
#scenario = "National Trends"

df = CSV.read("Results\\import_price_curves$(scenario)_$(year)_CY_$(CY_ts)_$(endtime).csv",DataFrame)

p1 = plot()
p2 = plot()
for import_level in imp_lvs
    prices = df[:,import_level]
    prices_without_voll = filter(p -> p <7999 , prices)

    pdc,levels = price_duration_curve(prices)
    pdc_array = [pdc[pl] for pl in levels]

    if 8000.0 in keys(pdc)
        nb_hours_voll = pdc[8000.0]
    else
        nb_hours_voll = 0
    end
    pdc_2,levels_2 = price_duration_curve(prices_without_voll)
    pdc_array_2 = [pdc_2[pl] for pl in levels_2]

    plot!(p1, pdc_array,levels, ylabel = "Price", xlabel = "Number of hours", title = "Price duration curve import $(scenario), $year",label = import_level)

    plot!(p2, pdc_array_2.+nb_hours_voll,levels_2, ylabel = "Price", xlabel = "Number of hours", title = "Price duration curve import $(scenario), $year",label = import_level)
    println(import_level, nb_hours_voll)
end
plot(p1)
savefig("Results\\Price duration curves$(scenario)_$(year)_CY_$(CY_ts)_$(endtime)_several_levels")
plot(p2)
savefig("Results\\Price duration curves$(scenario)_$(year)_CY_$(CY_ts)_$(endtime)_several_levels_VOLL_EXCL")

##
import_level = "-5000"
prices = df[:,import_level]
prices_without_voll = filter(p -> p <7999 , prices)

pdc,levels = price_duration_curve(prices)
pdc_array = [pdc[pl] for pl in levels]

if 8000.0 in keys(pdc)
    nb_hours_voll = pdc[8000.0]
else
    nb_hours_voll = 0
end
pdc_2,levels_2 = price_duration_curve(prices_without_voll)
pdc_array_2 = [pdc_2[pl] for pl in levels_2]
##
function price_duration_curve(prices)
    levels = Set(prices)
    levels = sort(collect(levels))
    #levels = 0:10:250
    price_count_dict = Dict(level => count(x-> x >=level, prices) for level in levels)
    return price_count_dict,levels
end
##
plot([production_dict["FR00","Nuclear",t] for t in 1:8760])
plot([production_dict["FR00","CCGT",t] for t in 1:8760])
plot([production_dict["DE00","CCGT",t] for t in 1:8760])
##
t = 1067
plot()
for scenario in scenarios
    df = CSV.read("Results\\import_price_curves$(scenario).csv",DataFrame)
    import_levels_int = [parse(Int,name) for name in names(df)]
    price_curve = [df[t,import_level] for import_level in names(df)]
    plot!(import_levels_int,price_curve, ylabel = "Price", xlabel = "Import level (MW)", title = "Import/export curves $(t)th hour", label = scenario,legend = :bottomright )
end
plot!()
savefig("Results\\Import-export curves $(t)th hour")

##
using Gurobi
scenario = "National Trends"
endtime = 24*20
year = 2040
CY = 1984
VOLL = 5000
CO2_price = 0.085

m = Model(optimizer_with_attributes(Gurobi.Optimizer))
define_sets!(m,scenario,year,CY)
process_parameters!(m,scenario,year,CY)
process_time_series!(m,scenario)
# remove_capacity_country(m,"BE00")
# set_demand_country(m,"BE00",1000)
#build_isolated_model_2!(m,endtime,VOLL,CO2_price)
#build_isolated_model_DSR_shift!(m,endtime,VOLL,CO2_price,VOLL/20)
#build_NTC_model!(m,endtime,VOLL,CO2_price)
build_NTC_model_DSR_shift!(m,endtime,VOLL,CO2_price,VOLL/10,0.25,VOLL/2)
optimize!(m)
sum([maximum(m.ext[:parameters][:connections]["BE00"][nb]) for nb in keys(m.ext[:parameters][:connections]["BE00"])])

import_level = "500"
df = CSV.read("Results\\import_price_curves$(scenario).csv",DataFrame)
prices = df[1:endtime,import_level]
plot(prices,label = "Import price $(import_level) MW",legend = :topleft, right_margin = 18Plots.mm)
country = "BE00"
plot!(twinx(),[-sum(JuMP.value(m.ext[:variables][:production][country,tech,t]) for tech in m.ext[:sets][:intermittent_technologies][country]) + m.ext[:timeseries][:demand][country][t] for t in 1:endtime],
    color = "red",label = "residual_demand BE (MW)", legend = :bottomright)
xlabel!("Timestep (hour)")
savefig("Results\\Price - RES correlation $(scenario), $(import_level) MW")

countries = ["BE00" "DE00" "FR00" "UK00" "NL00"]
ren_gen = Dict(country => sum(JuMP.value(m.ext[:variables][:production][country,tech,t]) for tech in m.ext[:sets][:intermittent_technologies][country], t in 1:endtime) for country in countries)
dem = Dict(country => sum(m.ext[:timeseries][:demand][country][t] for t in 1:endtime) for  country in countries)

sum()
