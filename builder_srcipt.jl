include("model_builder.jl")

using Gurobi
using TickTock

function create_isolated_model(m::Model,scenario::String,year::Int,CY::Int,endtime,VOLL,CO2_price)
    define_sets!(m,scenario,year,CY)
    process_parameters!(m,scenario,year,CY)
    process_time_series!(m,scenario)
    build_isolated_model_2!(m,endtime,VOLL,CO2_price)
end

function create_isolated_model_DSR(m::Model,scenario::String,year::Int,CY::Int,endtime,VOLL,CO2_price,dsr_price)
    define_sets!(m,scenario,year,CY)
    process_parameters!(m,scenario,year,CY)
    process_time_series!(m,scenario)
    build_isolated_model_DSR!(m,endtime,VOLL,CO2_price,dsr_price)
end
function create_NTC_model(m::Model,scenario::String,year::Int,CY::Int,endtime,VOLL,CO2_price)
    define_sets!(m,scenario,year,CY)
    process_parameters!(m,scenario,year,CY)
    process_time_series!(m,scenario)
    build_NTC_model!(m,endtime,VOLL,CO2_price)
end
function create_NTC_model_DSR(m::Model,scenario::String,year::Int,CY::Int,endtime,VOLL,CO2_price,dsr_price)
    define_sets!(m,scenario,year,CY)
    process_parameters!(m,scenario,year,CY)
    process_time_series!(m,scenario)
    build_NTC_model_DSR_shift!(m,endtime,VOLL,CO2_price,dsr_price,0.25,VOLL/2)
end
# using JLD2
# using FileIO
# using JLD
# using HDF5
# save("example.jld2",values_kept)
# JLD.save("example.jld",,values_kept)
##
using Gurobi

values_kept = Dict()
endtime = 24*10
year = 2040
CY = 1984
VOLL = 1000
CO2_price = 0.84
dsr_price = 200
scenarios = ["Distributed Energy" "Global Ambition" "National Trends"]
values_kept = Dict()
values_kept[:t_build] = Dict()
values_kept[:t_solve] = Dict()
values_kept[:costs] = Dict()
values_kept[:costs][:total] = Dict()
values_kept[:costs][:load_shedding_cost]= Dict()
values_kept[:costs][:CO2_cost]= Dict()
values_kept[:costs][:VOM_cost]= Dict()
values_kept[:costs][:fuel_cost] = Dict()
values_kept[:load_shedding] = Dict()
values_kept[:load_shedding][:absolute] = Dict()
values_kept[:load_shedding][:percentage] = Dict()
values_kept[:neighbors_load_shedding] = Dict()
values_kept[:neighbors_load_shedding][:absolute]  = Dict()
values_kept[:neighbors_load_shedding][:percentage]  = Dict()
values_kept[:net_import] = Dict()
values_kept[:demand] = Dict()
dsr = "DSR"

values_kept[:t_build][dsr] = Dict()
values_kept[:t_solve][dsr] = Dict()
values_kept[:costs][dsr] = Dict()
values_kept[:costs][:total][dsr] = Dict()
values_kept[:costs][:load_shedding_cost][dsr]= Dict()
values_kept[:costs][:CO2_cost][dsr]= Dict()
values_kept[:costs][:VOM_cost][dsr]= Dict()
values_kept[:costs][:fuel_cost][dsr] = Dict()
values_kept[:load_shedding][dsr] = Dict()
values_kept[:load_shedding][:absolute][dsr] = Dict()
values_kept[:load_shedding][:percentage][dsr] = Dict()
values_kept[:neighbors_load_shedding][dsr] = Dict()
values_kept[:neighbors_load_shedding][:absolute][dsr]  = Dict()
values_kept[:neighbors_load_shedding][:percentage][dsr]  = Dict()
values_kept[:net_import][dsr] = Dict()
values_kept[:demand][dsr] = Dict()
for scenario in scenarios
    @show(scenario)
    tick()
    m1 = Model(optimizer_with_attributes(Gurobi.Optimizer))
    if dsr == "No_DSR"
#        create_isolated_model(m1,scenario,year,CY,endtime,VOLL,CO2_price)
    elseif dsr == "DSR"
        create_isolated_model_DSR(m1,scenario,year,CY,endtime,VOLL,CO2_price,dsr_price)
    else
            @show("Problem!!!!!!!!!!!")
    end
    t_build_isolated = tok()
    tick()
    println("solving Isolated")
    optimize!(m1)
    t_solve_isolated = tok()

    # build_isolated_model!(m,endtime,1000,0.84)
        # optimize!(m)
    tick()
    m2 = Model(optimizer_with_attributes(Gurobi.Optimizer))
    if dsr == "No_DSR"
            create_NTC_model(m2,scenario,year,CY,endtime,VOLL,CO2_price)
    elseif dsr == "DSR"
            create_NTC_model_DSR(m2,scenario,year,CY,endtime,VOLL,CO2_price,dsr_price)
    else
            @show("Problem!!!!!!!!!!!")
    end

    t_build_NTC = tok()
    tick()
    optimize!(m2)
    t_solve_NTC = tok()
    t_build_scen = Dict("isolated" => t_build_isolated, "NTC" => t_build_NTC)
    values_kept[:t_build][dsr][scenario] = t_build_scen

    t_solve_scen = Dict("isolated" => t_solve_isolated, "NTC" => t_solve_NTC)
    values_kept[:t_solve][dsr][scenario] = t_solve_scen
    values_kept[:costs][:total][dsr][scenario] = Dict("isolated" => JuMP.objective_value.(m1), "NTC" => JuMP.objective_value.(m2))
    values_kept[:costs][:VOM_cost][dsr][scenario] = Dict("isolated" =>sum(JuMP.value.(m1.ext[:expressions][:VOM_cost])), "NTC" => sum(JuMP.value.(m2.ext[:expressions][:VOM_cost])))
    values_kept[:costs][:fuel_cost][dsr][scenario] = Dict("isolated" =>sum(JuMP.value.(m1.ext[:expressions][:fuel_cost])), "NTC" => sum(JuMP.value.(m2.ext[:expressions][:fuel_cost])))
    values_kept[:costs][:CO2_cost][dsr][scenario] = Dict("isolated" =>sum(JuMP.value.(m1.ext[:expressions][:CO2_cost])), "NTC" => sum(JuMP.value.(m2.ext[:expressions][:CO2_cost])))
    values_kept[:costs][:load_shedding_cost][dsr][scenario] = Dict("isolated" =>sum(JuMP.value.(m1.ext[:expressions][:load_shedding_cost])), "NTC" => sum(JuMP.value.(m2.ext[:expressions][:load_shedding_cost])))


    load_shedding_isolated = sum(JuMP.value.(m1.ext[:variables][:load_shedding]))
    load_shedding_NTC = sum(JuMP.value.(m2.ext[:variables][:load_shedding]))



    ls_neighbors_isolated_percent = Dict(country =>
            sum(JuMP.value.(m1.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
            /sum(m1.ext[:timeseries][:demand][country][ts]
            for ts in 1:endtime) for country in m1.ext[:sets][:connections]["BE00"])
    ls_neighbors_isolated_abs = Dict(country =>
            sum(JuMP.value.(m1.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
            for country in m1.ext[:sets][:connections]["BE00"])
    ls_neighbors_NTC_percent = Dict(country =>
            sum(JuMP.value.(m2.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
            /sum(m2.ext[:timeseries][:demand][country][ts]
            for ts in 1:endtime) for country in m2.ext[:sets][:connections]["BE00"])
    ls_neighbors_NTC_abs = Dict(country =>
            sum(JuMP.value.(m2.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
            for country in m2.ext[:sets][:connections]["BE00"])

    values_kept[:neighbors_load_shedding][:absolute][dsr][scenario] = Dict("isolated" => ls_neighbors_isolated_abs, "NTC" => ls_neighbors_NTC_abs )
    values_kept[:neighbors_load_shedding][:percentage][dsr][scenario] = Dict("isolated" => ls_neighbors_isolated_percent, "NTC" => ls_neighbors_NTC_percent)


    ls_isolated_percent = Dict(country =>
            sum(JuMP.value.(m1.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
            /sum(m1.ext[:timeseries][:demand][country][ts]
            for ts in 1:endtime) for country in m1.ext[:sets][:countries])
    ls_isolated_abs = Dict(country =>
            sum(JuMP.value.(m1.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
            for country in m1.ext[:sets][:countries])
    ls_NTC_percent = Dict(country =>
            sum(JuMP.value.(m2.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
            /sum(m2.ext[:timeseries][:demand][country][ts]
            for ts in 1:endtime) for country in m2.ext[:sets][:countries])
    ls_NTC_abs = Dict(country =>
            sum(JuMP.value.(m2.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
            for country in m2.ext[:sets][:countries])

    values_kept[:load_shedding][:absolute][dsr][scenario] = Dict("isolated" => ls_isolated_abs, "NTC" => ls_NTC_abs )
    values_kept[:load_shedding][:percentage][dsr][scenario] = Dict("isolated" => ls_isolated_percent, "NTC" => ls_NTC_percent)

    net_import = Dict(country =>
            sum(JuMP.value.(m2.ext[:variables][:import][country,neighbor,ts]) - JuMP.value.(m2.ext[:variables][:export][country,neighbor,ts])  for ts in 1:endtime,neighbor in m2.ext[:sets][:connections][country])
            for country in vcat(m2.ext[:sets][:connections]["BE00"],"BE00"))
        values_kept[:net_import][dsr][scenario] = net_import

    demand = Dict(country =>
            sum(JuMP.value.(m2.ext[:timeseries][:demand][country][ts])  for ts in 1:endtime)
            for country in m2.ext[:sets][:countries])
                values_kept[:demand][dsr][scenario] = demand
end
scen = "Distributed Energy"
dsr = "DSR"

ls = sum(values_kept[:load_shedding][:absolute][dsr][scen]["NTC"][country] for country in keys(values_kept[:load_shedding][:absolute][dsr][scen]["NTC"]))
ls = sum(values_kept[:load_shedding][:absolute][dsr][scen]["isolated"][country] for country in keys(values_kept[:load_shedding][:absolute][dsr][scen]["NTC"]))

dem = sum(values_kept[:demand][dsr][scen][country] for country in keys(values_kept[:load_shedding][:absolute][dsr][scen]["NTC"]))

ls/dem

ls =sum(values_kept[:neighbors_load_shedding][:absolute][dsr][scen]["NTC"][country] for country in keys(values_kept[:neighbors_load_shedding][:absolute][dsr][scen]["NTC"]))
ls = sum(values_kept[:neighbors_load_shedding][:absolute][dsr][scen]["isolated"][country] for country in keys(values_kept[:neighbors_load_shedding][:absolute][dsr][scen]["NTC"]))

dem = sum(values_kept[:demand][dsr][scen][country] for country in keys(values_kept[:neighbors_load_shedding][:absolute][dsr][scen]["NTC"]))


net_import = values_kept[:net_import][dsr][scen]["BE00"]
dem = values_kept[:demand][dsr][scen]["BE00"]

net_import/dem

total_cost = values_kept[:costs][:total][dsr][scen]["isolated"]
ls_cost = values_kept[:costs][:load_shedding_cost][dsr][scen]["isolated"]
dem = sum(values_kept[:demand][dsr][scen][country] for country in keys(values_kept[:load_shedding][:absolute][dsr][scen]["NTC"]))
total_cost/dem


total_cost = values_kept[:costs][:total][dsr][scen]["NTC"]
ls_cost = values_kept[:costs][:load_shedding_cost][dsr][scen]["NTC"]
dem = sum(values_kept[:demand][dsr][scen][country] for country in keys(values_kept[:load_shedding][:absolute][dsr][scen]["NTC"]))
total_cost/dem



##
sum(JuMP.value.(m.ext[:variables][:import]))
sum(JuMP.value.(m.ext[:variables][:export]))
sum(JuMP.value.(m.ext[:variables][:production]))
sum(JuMP.value.(m.ext[:expressions][:fuel_cost]))

JuMP.value.(m.ext[:variables][:import])
m.ext[:sets][:connections]["FR15"]
JuMP.value.(m.ext[:variables][:import])
JuMP.value.(m.ext[:expressions][:fuel_cost])
##

JuMP.dual.(m.ext[:constraints][:demand_met])

m.ext[:constraints]
sum(JuMP.value.(m2.ext[:expressions][:fuel_cost]))
sum(JuMP.value.(m2.ext[:expressions][:VOM_cost]))
sum(JuMP.value.(m2.ext[:expressions][:CO2_cost]))
sum(JuMP.value.(m2.ext[:expressions][:load_shedding_cost]))
sum(JuMP.value.(m2.ext[:expressions][:transport_cost]))


sum(JuMP.value.(m1.ext[:variables][:load_shedding]))
sum(JuMP.value.(m2.ext[:variables][:load_shedding]))
sum(JuMP.value.(m2.ext[:variables][:water_dumping]))
sum(JuMP.value.(m2.ext[:variables][:curtailment]))

sum(JuMP.value.(m.ext[:variables][:load_shedding]["FR00",i]) for i in 1:endtime)
sum(JuMP.value.(m.ext[:variables][:curtailment]["BE00",i]) for i in 1:1000)
sum(JuMP.value.(m.ext[:expressions][:total_production_timestep]["BE00",i]) for i in 1:1000)

ls = Dict( country =>
    sum(JuMP.value.(m.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
    /sum(m.ext[:timeseries][:demand][country][ts]
    for ts in 1:endtime) for country in m.ext[:sets][:countries])

ls_2 = Dict( country =>
    sum(JuMP.value.(m2.ext[:variables][:load_shedding][country,ts]) for ts in 1:endtime)
    for country in m2.ext[:sets][:countries])
sum(JuMP.value.(m.ext[:variables][:production]))
(sum(JuMP.value.(m2.ext[:variables][:load_shedding]))) /
    sum(sum(m2.ext[:timeseries][:demand][country][1:endtime] for country in m2.ext[:sets][:countries]))
plot(Dict( k => v  for (k,v) in ls_2 if v>0))
ls_2["BE00"]
ls_2["DE00"]
##
using Plots
# country = "BE00"
# m2.ext[:parameters][:technologies][:capacities][country]
#
# starttime = 1
# endtime = 24*100
# plot(m2.ext[:timeseries][:demand][country][starttime:endtime], label = "demand")
# plot!([JuMP.value.(m2.ext[:expressions][:total_production_timestep][country,ts]) for ts in starttime:endtime],label = "Production")
# plot!([JuMP.value.(m2.ext[:variables][:load_shedding][country,ts]) for ts in starttime:endtime], label = "load shedding")
#
#
# plot!([JuMP.value.(m2.ext[:variables][:soc][country,"Battery",ts]) for ts in starttime:endtime], label = "soc_bat")
# plot!([JuMP.value.(m2.ext[:variables][:soc][country,"PS_C",ts]) for ts in starttime:endtime], label = "soc_PS_C")
# plot!([JuMP.value.(m2.ext[:variables][:soc][country,"PS_O",ts]) for ts in starttime:endtime], label = "soc_PS_O")
#
#
# plot!([JuMP.value.(m2.ext[:variables][:production][country,"CCGT",ts]) for ts in starttime:endtime],label = "CCGT")
# plot!([JuMP.value.(m2.ext[:variables][:production][country,"OCGT",ts]) for ts in starttime:endtime],label = "OCGT")
# plot!([JuMP.value.(m2.ext[:variables][:production][country,"Coal",ts]) for ts in starttime:endtime],label = "Coal")
# plot!([JuMP.value.(sum(m2.ext[:variables][:production][country,ren_tech,ts] for ren_tech in m2.ext[:sets][:intermittent_technologies][country])) for ts in starttime:endtime],label = "Renewable_prod")
# plot!([JuMP.value.(m2.ext[:variables][:production][country,"Nuclear",ts]) for ts in starttime:endtime],label = "Nuclear")
# plot!([JuMP.value.(m2.ext[:variables][:production][country,"PS_O",ts]) for ts in starttime:endtime],label = "PS_O")
# plot!([JuMP.value.(m2.ext[:variables][:production][country,"PS_C",ts]) for ts in starttime:endtime],label = "PS_C")
#
# [JuMP.value.(m2.ext[:variables][:production][country,"PS_C",ts]) for ts in starttime:endtime][19:30]
#
# plot!([sum(JuMP.value.(m2.ext[:variables][:import][country,neighbor,ts]) for neighbor in m2.ext[:sets][:connections][country])  for ts in starttime:endtime],label = "Import")
# plot!([sum(JuMP.value.(m2.ext[:variables][:export][country,neighbor,ts]) for neighbor in m2.ext[:sets][:connections][country])  for ts in starttime:endtime],label = "Export")
#
# sum(JuMP.value.(m.ext[:expressions][:load_shedding_cost][country,ts] for ts in 1:endtime))

scenario = "Distributed Energy"


endtime = 24*10

m_iso = Model(optimizer_with_attributes(Gurobi.Optimizer))
create_isolated_model_DSR(m_iso,scenario,year,CY,endtime,VOLL,CO2_price,100)
optimize!(m_iso)


sum(JuMP.value.(m_iso.ext[:variables][:load_shedding][country,ts]) for country in m_iso.ext[:sets][:countries], ts in 1:endtime)
sum(JuMP.value.(m_iso.ext[:timeseries][:demand][country][ts]) for country in m_iso.ext[:sets][:countries], ts in 1:endtime)

sum(JuMP.value.(m_iso.ext[:variables][:load_shedding][country,ts]) for country in m_iso.ext[:sets][:connections]["BE00"], ts in 1:endtime)

sum(JuMP.value.(m1.ext[:variables][:load_shedding]))
sum(JuMP.value.(m1.ext[:variables][:DSR]))


m_iso_no_DSR = Model(optimizer_with_attributes(Gurobi.Optimizer))
create_isolated_model(m_iso_no_DSR,scenario,year,CY,endtime,VOLL,CO2_price)
optimize!(m_iso_no_DSR)

m_iso_no_DSR.ext[:sets][:technologies]["DE00"]
m_iso_no_DSR.ext[:sets][:flat_run_technologies]["DE00"]
m_iso_no_DSR.ext[:parameters][:technologies][:total_gen]["UK00"]

country = "DE00"
tech = "Other RES"
reading = CSV.read("Input Data\\gen_prod.csv",DataFrame)
reading = reading[reading[!,"Scenario"] .== scenario,:]
reading = reading[reading[!,"Year"] .== year,:]
reading = reading[reading[!,"Climate Year"] .== CY,:]
reading_country = reading[reading[!,"Node"] .== country,:]
reading_country[reading_country[!,"Generator_ID"] .== tech,:].Value
reading_country[reading_country[!,"Generator_ID"] .== tech,:].Value
sum(JuMP.value.(m_iso_no_DSR.ext[:variables][:load_shedding][country,ts]) for country in m_iso.ext[:sets][:countries], ts in 1:endtime)/
    sum(JuMP.value.(m_iso_no_DSR.ext[:timeseries][:demand][country][ts]) for country in m_iso.ext[:sets][:countries], ts in 1:endtime)

scenario = "Distributed Energy"
m2 = Model(optimizer_with_attributes(Gurobi.Optimizer))
create_NTC_model(m2,scenario,year,CY,endtime,VOLL,CO2_price)
optimize!(m2)

m2 = Model(optimizer_with_attributes(Gurobi.Optimizer))
create_NTC_model_DSR(m2,scenario,year,CY,endtime,VOLL,CO2_price,200)
optimize!(m2)

sum(JuMP.value.(m2.ext[:variables][:DSR]))
sum(JuMP.value.(m2.ext[:variables][:load_shedding]))

country = "NON1"
water = Dict()
dem = Dict()
water_percent = Dict()
for country in m2.ext[:sets][:countries]
    if !isempty(m2.ext[:sets][:hydro_flow_technologies][country])
        w = sum(JuMP.value.(m2.ext[:variables][:production][country,tech,ts]) for tech in m2.ext[:sets][:hydro_flow_technologies][country], ts in 1:endtime)
        water[country] = w
        d = sum(m2.ext[:timeseries][:demand][country][ts] for ts in 1:endtime)
        dem[country] = d
         water_percent[country] = w/d
    end
end

sum(values(water))
sum(values(water))/ sum(values(dem))


water_percent["DE00"]
water / dem
m2.ext[:variables][:production]

function plot_production_country(m,country,starttime,endtime)
    all_tech = m2.ext[:sets][:technologies][country]
    d = m2.ext[:sets][:dispatchable_technologies][country]
    soc = m2.ext[:sets][:soc_technologies][country]
    ig = m2.ext[:sets][:intermittent_technologies][country]
    storage =  m2.ext[:sets][:storage_technologies][country]

    neighbors = m2.ext[:sets][:connections][country]
    @assert(issetequal(all_tech,vcat(d,soc,ig)))

    prod_lines = Dict(
    "ren" => [JuMP.value.(sum(m2.ext[:variables][:production][country,ren_tech,ts] for ren_tech in ig)) for ts in starttime:endtime],
    "conv" => [JuMP.value.(sum(m2.ext[:variables][:production][country,disp_tech,ts] for disp_tech in d)) for ts in starttime:endtime],
    "soc" => [JuMP.value.(sum(m2.ext[:variables][:production][country,soc_tech,ts] for soc_tech in soc)) for ts in starttime:endtime]
        .-  [JuMP.value.(sum(m2.ext[:variables][:charge][country,charging_tech,ts] for charging_tech in storage)) for ts in starttime:endtime],
    "imp" => [JuMP.value.(sum(m2.ext[:variables][:import][country,nb,ts] for nb in neighbors)) for ts in starttime:endtime]
        .- [JuMP.value.(sum(m2.ext[:variables][:export][country,nb,ts] for nb in neighbors)) for ts in starttime:endtime]
    )

    demand = m.ext[:timeseries][:demand][country][starttime:endtime]
    plot(demand, label = "demand")
    plot!(prod_lines["conv"],label = "conv")
    plot!(prod_lines["soc"] ,label = "soc")
    plot!(prod_lines["ren"]  ,label = "ren")
    plot!(prod_lines["imp"]  ,label = "Net import",legend = :outerleft)
    xlabel!("Time")
    ylabel!("Production (MW)")
    title!("Dispatch Decisions $country")
end
##

plot_production_country(m2,"DE00",1,1+24*50)
savefig("fig1")
country = "FI00"
m.ext[:sets][:technologies][country]
m.ext[:sets][:intermittent_technologies][country]
m.ext[:sets][:dispatchable_technologies][country]
m.ext[:sets][:storage_technologies][country]
m.ext[:sets][:hydro_flow_technologies][country]
m.ext[:sets][:hydro_flow_technologies_without_pumping][country]
m.ext[:sets][:hydro_flow_technologies_with_pumping][country]

vcat(m.ext[:sets][:hydro_flow_technologies][country],"PS_C")


m.ext[:sets][:intermittent_technologies]["FR00"]
m.ext[:sets][:storage_technologies]["FR00"]

m.ext[:sets][:connections]


m1.ext[:sets][:connections]["LUB1"]
m.ext[:sets][:connections]["DE00"]
##
m.ext[:parameters]
m.ext[:parameters][:connections]["DE00"]["FR00"]
m.ext[:parameters][:connections]["LUB1"]["BE00"]
m.ext[:parameters][:connections]["BE00"]["LUB1"]

m.ext[:parameters][:technologies][:capacities]["FR15"]
sum(m.ext[:parameters][:technologies]["BE00"][key] for key in keys(m.ext[:parameters][:technologies]["BE00"]))

m.ext[:parameters][:technologies][:energy_capacities]["NON1"]

m.ext[:parameters][:technologies][:energy_capacities]["ITSI"]
m.ext[:parameters][:technologies][:capacities]["ITSI"]



##
m.ext[:timeseries][:inter_gen]["BE00"]
m.ext[:timeseries][:hydro_inflow]["AT00"]
##
m.ext[:constraints]
m.ext[:constraints][:demand_met]["BE00",1]
m.ext[:constraints][:intermittent_production]["BE00","w_on",1]

m.ext[:constraints][:soc_evolution_inflow]["ITSI","ROR",2]

m.ext[:constraints][:soc_limit]["BE00", "ROR",2]
##
#Check if all lines from sets are represented in parameters
for node1 in m.ext[:sets][:countries]
    ncs = length(m.ext[:sets][:connections][node1])
    ncp = length(m.ext[:parameters][:connections][node1])
    @assert(ncs == ncp)
end

setdiff([1 2],[2,3])
#Check if every line has capacity
for node1 in keys(m.ext[:sets][:connections])
    for node2 in m.ext[:sets][:connections][node1]
        @assert(!(isempty(m.ext[:parameters][:connections][node1][node2])))
        @assert(!(isempty(m.ext[:parameters][:connections][node2][node1])))
        @show(m.ext[:parameters][:connections][node2][node1] == m.ext[:parameters][:connections][node1][node2])
        @assert(m.ext[:parameters][:connections][node2][node1] == m.ext[:parameters][:connections][node1][node2])
    end
end
m.ext[:parameters][:connections]["NON1"]["NOM1"]
m.ext[:parameters][:connections]["NOM1"]["NON1"]

(reading_lines[!,"Year"] .== year) .& (reading_lines[!,"Year"] .== year)

reading_lines[reading_lines[!,"Year"] .== year,:]
