include("model_builder.jl")
using Gurobi

scenario = "Distributed Energy"
endtime = 24*100
year = 2040
CY = 1984
VOLL = 1000
CO2_price = 0.84

m = Model(optimizer_with_attributes(Gurobi.Optimizer))
define_sets!(m,scenario,year,CY)
process_parameters!(m,scenario,year,CY)
process_time_series!(m,scenario)
#build_isolated_model_2!(m,endtime,VOLL,CO2_price)
build_NTC_model!(m,endtime,VOLL,CO2_price)
optimize!(m)

sum(JuMP.value.(m.ext[:variables][:load_shedding]))/sum(JuMP.value.(m.ext[:variables][:production]))
sum(JuMP.value.(m.ext[:variables][:production]))
sum(JuMP.value.(m.ext[:timeseries][:demand][country][ts]) for country in m.ext[:sets][:countries], ts in 1:endtime)

c = "UK00"
sum(JuMP.value.(m.ext[:variables][:production][c,tech,t]) for tech in m.ext[:sets][:flat_run_technologies][c], t in 1:endtime)*8760/endtime
sum(JuMP.value.(m.ext[:variables][:production][c,tech,t]) for tech in m.ext[:sets][:technologies][c], t in 1:endtime)*8760/endtime


sum(JuMP.value.(m.ext[:variables][:production]), dims = 2)
