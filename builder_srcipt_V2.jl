include("model_builder.jl")
using Gurobi
using Plots

scenario = "Distributed Energy"
endtime = 24*10
year = 2040
CY = 1984
VOLL = 1000
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

country = "BE00"
plot([JuMP.dual.(m.ext[:constraints][:demand_met][country,t]) for t in 1:endtime],right_margin = 18Plots.mm,label = "Price")
plot!([JuMP.dual.(m.ext[:constraints][:demand_met][country,t]) for t in 1:endtime],right_margin = 18Plots.mm,label = "Price")
plot!(twinx(),[-sum(JuMP.value(m.ext[:variables][:production][country,tech,t]) for tech in m.ext[:sets][:intermittent_technologies][country]) + m.ext[:timeseries][:demand][country][t] for t in 1:endtime],
    color = "red",label = "residual_demand", legend = :bottomright)

t=20

sum(JuMP.value.(m.ext[:variables][:import][country,neighbor,t] for neighbor in m.ext[:sets][:connections][country]))
sum(JuMP.value.(m.ext[:variables][:export][country,neighbor,t] for neighbor in m.ext[:sets][:connections][country]))
JuMP.dual.(m.ext[:constraints][:demand_met][country,t] for t in 1:endtime)

sum(JuMP.value.(m.ext[:variables][:DSR_down]))
sum(JuMP.value.(m.ext[:variables][:DSR_up]))
sum(JuMP.value.(m.ext[:variables][:DSR_shed]))

sum(JuMP.value.(m.ext[:variables][:load_shedding]))/sum(JuMP.value.(m.ext[:variables][:production]))
sum(JuMP.value.(m.ext[:variables][:load_shedding]["BE00",t]) for t in 1:endtime)/sum(JuMP.value.(m.ext[:timeseries][:demand]["BE00"][t]) for t in 1:endtime)
ls_neighbors_NTC_percent = Dict(country =>
    sum(JuMP.value.(m.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
    /sum(m.ext[:timeseries][:demand][country][ts]
    for ts in 1:endtime) for country in m.ext[:sets][:connections]["BE00"])


sum(JuMP.value.(m.ext[:variables][:production]))
sum(JuMP.value.(m.ext[:timeseries][:demand][country][ts]) for country in m.ext[:sets][:countries], ts in 1:endtime)

country = "DE00"

plot([sum(JuMP.value.(m.ext[:variables][:soc][country,tech,t] for tech in m.ext[:sets][:soc_technologies][country])) for t in 1:endtime])
plot!([sum(JuMP.value.(m.ext[:variables][:soc][country,tech,t] for tech in m.ext[:sets][:soc_technologies][country])) for t in 1:endtime])
