include("model_builder.jl")
using Gurobi
using Plots
using Revise

peak_demand = Dict()
total_demand = Dict()

scenario = "Distributed Energy"
#scenario = "Global Ambition"
#scenario = "National Trends"
endtime = 24*100
year = 2030
CY_cap = 1984
CY_ts = 2009
VOLL = 10000
CO2_price = 0.085

m = Model(optimizer_with_attributes(Gurobi.Optimizer))
define_sets!(m,scenario,year,CY_cap,[])
process_parameters!(m,scenario,year,CY_cap)
process_time_series!(m,scenario,year,CY_ts)


country = "AT00"
length(m.ext[:timeseries][:hydro_inflow][country]["ROR"])

build_NTC_model!(m,endtime,VOLL)
optimize!(m)


peak_demand[year] = maximum([sum(JuMP.value.(m.ext[:timeseries][:demand][country][ts]) for country in m.ext[:sets][:countries]) for ts in 1:endtime])
total_demand[year] = sum([sum(JuMP.value.(m.ext[:timeseries][:demand][country][ts]) for country in m.ext[:sets][:countries]) for ts in 1:endtime])


tech_reading = CSV.read(joinpath("Input Data","time_series_output",string("RES","_$CY",".csv")),DataFrame)
dropmissing(tech_reading)

sum(JuMP.value.(m.ext[:variables][:production]))
sum(JuMP.value.(m.ext[:variables][:load_shedding]))
sum(JuMP.value.(m.ext[:variables][:curtailment]))
sum(JuMP.value.(m.ext[:variables][:load_shedding]))/sum(JuMP.value.(m.ext[:variables][:production]))

JuMP.value.(m.ext[:variables][:production])

c = "BE00"
[sum(JuMP.value.(m.ext[:variables][:production])[c,tech,time] for time in 1:endtime) for tech in m.ext[:sets][:technologies][c]]
countries = ["BE00"]

production = Dict()
for c in countries
    for tech in m.ext[:sets][:technologies][c]
        production[tech] + = JuMP.value.(m.ext[:variables][:production])[c,tech,time]
    end
end
