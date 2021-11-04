include("model_builder.jl")
using Gurobi
using Plots

scenario = "Distributed Energy"
endtime = 24*150
year = 2030
CY = 1984
VOLL = 1000
CO2_price = 0.085

m = Model(optimizer_with_attributes(Gurobi.Optimizer))
define_sets!(m,scenario,year,CY)
process_parameters!(m,scenario,year,CY)
process_time_series!(m,scenario)
#build_isolated_model_2!(m,endtime,VOLL,CO2_price)
#build_isolated_model_DSR_shift!(m,endtime,VOLL,CO2_price,VOLL/20)
#build_NTC_model!(m,endtime,VOLL,CO2_price)
build_NTC_model_DSR_shift!(m,endtime,VOLL,CO2_price,VOLL/10)
optimize!(m)

country = "BE00"
plot([JuMP.dual.(m.ext[:constraints][:demand_met][country,t]) for t in 1:endtime],right_margin = 18Plots.mm,label = "Price")
plot!(twinx(),[-sum(JuMP.value(m.ext[:variables][:production][country,tech,t]) for tech in m.ext[:sets][:intermittent_technologies][country]) + m.ext[:timeseries][:demand][country][t] for t in 1:endtime],
    color = "red",label = "residual_demand", legend = :bottomright)

sum(JuMP.value.(m.ext[:variables][:DSR_down]))
sum(JuMP.value.(m.ext[:variables][:DSR_up]))
sum(JuMP.value.(m.ext[:variables][:load_shedding]))/sum(JuMP.value.(m.ext[:variables][:production]))
sum(JuMP.value.(m.ext[:variables][:production]))
sum(JuMP.value.(m.ext[:timeseries][:demand][country][ts]) for country in m.ext[:sets][:countries], ts in 1:endtime)

c = "UK00"
sum(JuMP.value.(m.ext[:variables][:production][c,tech,t]) for tech in m.ext[:sets][:flat_run_technologies][c], t in 1:endtime)*8760/endtime
sum(JuMP.value.(m.ext[:variables][:production][c,tech,t]) for tech in m.ext[:sets][:technologies][c], t in 1:endtime)*8760/endtime


sum(JuMP.value.(m.ext[:variables][:production]), dims = 2)
