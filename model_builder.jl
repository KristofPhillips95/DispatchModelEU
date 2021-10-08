## Step 0: Activate environment - ensure consistency accross computers
using Pkg
Pkg.activate(@__DIR__) # @__DIR__ = directory this script is in
Pkg.instantiate()
##


function define_sets(m::Model,scenario::String,year::Int,CY::Int)
    m.ext[:sets] = Dict()
    m.ext[:sets][:technologies] = Dict()

    reading = CSV.read("Input Data\\gen_cap.csv",DataFrame)
    reading = reading[reading[!,"Scenario"] .== scenario,:]
    reading = reading[reading[!,"Year"] .== year,:]
    reading = reading[reading[!,"Climate Year"] .== CY,:]

    m.ext[:sets][:countries] = [country for country in Set(reading[!,"Node/Line"])]

    for country in m.ext[:sets][:countries]
        technologies = Set(reading[reading[!,"Node/Line"] .== country,:Generator_ID])
        m.ext[:sets][:technologies][country] = [tech for tech in technologies]
    end
end

##
function build_simple_copper_plate_model!(m::Model,endtime,renewable_target)
    #Extract relevant sets

    dispatchable_technologies = m.ext[:sets][:dispatchable_technologies]
    variable_technologies =  m.ext[:sets][:variable_technologies]

    technologies = m.ext[:sets][:technologies]
    countries =  m.ext[:sets][:countries]

    technologies_all_countries = m.ext[:sets][:technologies_all_countries]
    timesteps = collect(1:endtime)
    nb_steps = length(timesteps)
    #And extract relevant parameters
    variable_cost = m.ext[:parameters][:technology_cost][:variable_cost]
    fixed_cost = m.ext[:parameters][:technology_cost][:fixed_cost]

    demand = m.ext[:timeseries][:demand]
    renewables = m.ext[:timeseries][:renewables]
    #initialize dictionaries for variables, constraints and expressions
    m.ext[:variables] = Dict()
    m.ext[:expressions] = Dict()
    m.ext[:constraints] = Dict()

    #Variable instantiation
    installed_capacity = m.ext[:variables][:installed_capacity] = @variable(m,[c = countries, tech=technologies[c]],base_name = "installed_capacity")
    installed_capacity_renew = m.ext[:variables][:installed_capacity_renew] = @variable(m, [c=countries, tech = collect(keys(variable_technologies[c])), type =variable_technologies[c][tech]] ,  base_name =  "installed_capacity_renew")
    production = m.ext[:variables][:production] = @variable(m,[c= countries, tech=technologies[c],time=timesteps],base_name = "production")
    curtailment = m.ext[:variables][:curtailment] = @variable(m,[c=countries,time = timesteps],base_name = "curtailment")

    #Relevant expressions
    total_production_timestep = m.ext[:expressions][:total_production_timestep] =
      @expression(m, [c = countries, time = timesteps], sum(production[c,tech,time] for tech in technologies[c]))
    total_production_technology = m.ext[:expressions][:total_production_technology] =
     @expression(m, [c = countries, tech = technologies[c]], sum(production[c,tech,time] for time in timesteps))

    production_cost = m.ext[:expressions][:production_cost] =
     @expression(m, [c = countries, tech = technologies[c], time = timesteps], endtime/nb_steps*production[c,tech,time]*variable_cost[c][tech])
    investment_cost = m.ext[:expressions][:investment_cost] =
     @expression(m,[c=countries, tech = technologies[c]], 1000*installed_capacity[c,tech]*fixed_cost[c][tech])

    installed_capacity_summed_over_countries  = m.ext[:expressions][:installed_capacity_summed_over_countries] = @expression(m,[tech = keys(technologies_all_countries)], sum(installed_capacity[c,tech] for c in technologies_all_countries[tech]) )
    #Constraints
     m.ext[:constraints][:demand_met] = @constraint(m,[time = timesteps],
         sum(total_production_timestep[c,time] for c in countries) - sum(curtailment[c,time] for c in countries)  == sum(demand[c][time] for c in countries)
     )
    m.ext[:constraints][:production_capacity] = @constraint(m,[c = countries, tech = technologies[c], time = timesteps],
        production[c,tech,time] <= installed_capacity[c,tech]
    )
    m.ext[:constraints][:investment_renewable] = @constraint(m,[c = countries, tech = keys(variable_technologies[c])],
        installed_capacity[c,tech] == sum(installed_capacity_renew[c,tech,type] for type in variable_technologies[c][tech])
    )

    m.ext[:constraints][:production_renewable] = @constraint(m,[c = countries, tech = keys(variable_technologies[c]), time = timesteps],
        production[c,tech,time] == sum(renewables[c][tech][type][time]*installed_capacity_renew[c,tech,type] for type in variable_technologies[c][tech])
    )

    m.ext[:constraints][:installed_capacity_positive] = @constraint(m,[c = countries, tech = technologies[c]],
        0<= installed_capacity[c,tech]
    )
    m.ext[:constraints][:installed_capacity_positive_renew] = @constraint(m,[c=countries, tech = collect(keys(variable_technologies[c])), type =variable_technologies[c][tech]],
        0<= installed_capacity_renew[c,tech,type]
    )
    m.ext[:constraints][:production_positive] = @constraint(m,[c = countries, tech = technologies[c],time = timesteps],
        0<= production[c,tech,time]
    )
    m.ext[:constraints][:curtailment_positive] = @constraint(m,[c = countries,time = timesteps],
        0<= curtailment[c,time]
    )
    m.ext[:constraints][:curtailment_max] = @constraint(m,[c = countries,time = timesteps],
        curtailment[c,time]<= sum(production[c,tech,time] for tech in keys(variable_technologies[c]) )
    )
    m.ext[:constraints][:production_required_renewable] = @constraint(m,
        sum(total_production_technology[c,tech] for c in countries, tech in keys(variable_technologies[c])) - sum(curtailment) >= renewable_target*sum(sum(demand[c][1:endtime] for c in countries))
    )
    #Objective
    m.ext[:objective] = @objective(m,Min, sum(production_cost) + sum(investment_cost))
end


function build_simple_NTC_model!(m:: Model,endtime,renewable_target)

        build_simple_copper_plate_model!(m,endtime,renewable_target)

        dispatchable_technologies = m.ext[:sets][:dispatchable_technologies]
        variable_technologies =  m.ext[:sets][:variable_technologies]

        technologies = m.ext[:sets][:technologies]
        countries =  m.ext[:sets][:countries]

        technologies_all_countries = m.ext[:sets][:technologies_all_countries]
        #TODO better formulation
        timesteps = collect(1:endtime)
        nb_steps = length(timesteps)
        #And extract relevant parameters
        variable_cost = m.ext[:parameters][:technology_cost][:variable_cost]
        fixed_cost = m.ext[:parameters][:technology_cost][:fixed_cost]

        demand = m.ext[:timeseries][:demand]
        renewables = m.ext[:timeseries][:renewables]

        total_production_timestep = m.ext[:expressions][:total_production_timestep]
        curtailment = m.ext[:variables][:curtailment]

        #Remove the global balance constraint
        t = @elapsed begin
            for t in timesteps
                delete(m,m.ext[:constraints][:demand_met][t])
            end
        end
        @show(t)
        m.ext[:constraints][:demand_met_per_country] = @constraint(m,[c = countries, time = timesteps],
        total_production_timestep[c,time] - curtailment[c,time] == demand[c][time])
end

using JuMP
using Gurobi
using DataFrames
using CSV


reading = CSV.read("Input Data\\gen_cap.csv",DataFrame)
scenario = "Distributed Energy"
year = 2040
CY = 1984
reading = CSV.read("Input Data\\gen_cap.csv",DataFrame)
reading = reading[reading[!,"Scenario"] .== scenario,:]
reading = reading[reading[!,"Year"] .== year,:]
reading = reading[reading[!,"Climate Year"] .== CY,:]
country = "BE00"
reading[reading[!,"Node/Line"] .== country,:Generator_ID]

m = Model(optimizer_with_attributes(Gurobi.Optimizer))
define_sets(m,"Distributed Energy", 2040,1984)
m.ext[:sets]
