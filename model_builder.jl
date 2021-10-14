## Step 0: Activate environment - ensure consistency accross computers
using Pkg
Pkg.activate(@__DIR__) # @__DIR__ = directory this script is in
Pkg.instantiate()
using JuMP
using DataFrames
using CSV

##


function define_sets!(m::Model,scenario::String,year::Int,CY::Int)

    m.ext[:sets] = Dict()
    m.ext[:sets][:technologies] = Dict()
    m.ext[:sets][:dispatchable_technologies] = Dict()
    m.ext[:sets][:intermittent_technologies] = Dict()
    m.ext[:sets][:connections] = Dict()


    reading = CSV.read("Input Data\\gen_cap.csv",DataFrame)
    reading = reading[reading[!,"Scenario"] .== scenario,:]
    reading = reading[reading[!,"Year"] .== year,:]
    reading = reading[reading[!,"Climate Year"] .== CY,:]

    m.ext[:sets][:countries] = [country for country in Set(reading[!,"Node"])]

    for country in m.ext[:sets][:countries]
        technologies = Set(reading[reading[!,"Node"] .== country,:Generator_ID])
        m.ext[:sets][:technologies][country] = [tech for tech in technologies]
        m.ext[:sets][:dispatchable_technologies][country] = filter(tech -> (tech != "w_on") && (tech != "PV") && (tech != "w_off"),m.ext[:sets][:technologies][country])
    end

    reading_lines = CSV.read("Input Data\\lines.csv",DataFrame)
    reading_lines = reading_lines[reading_lines[!,"Scenario"] .== scenario,:]
    reading_lines = reading_lines[reading_lines[!,"Climate Year"] .== CY,:]
    reading_lines = reading_lines[reading_lines[!,"Year"] .== year,:]

    m.ext[:sets][:connections] = Dict(country => [] for country in m.ext[:sets][:countries])
    for country in m.ext[:sets][:countries]
        print(country)
        reading_lines_country = reading_lines[reading_lines[!,"Node1"] .== country,:]
        for other_country in reading_lines_country.Node2
            println(other_country)
            if !(other_country in m.ext[:sets][:connections][country])
                m.ext[:sets][:connections][country] = vcat(m.ext[:sets][:connections][country],other_country)
            end
            if !(country in m.ext[:sets][:connections][other_country])
                m.ext[:sets][:connections][other_country] = vcat(m.ext[:sets][:connections][other_country],country)
            end
        end
    end
end

function process_parameters!(m::Model,scenario::String,year::Int,CY::Int)
    countries = m.ext[:sets][:countries]
    technologies = m.ext[:sets][:technologies]
    connections = m.ext[:sets][:connections]

    m.ext[:parameters] = Dict()

    m.ext[:parameters][:technologies] = Dict()
    m.ext[:parameters][:connections] = Dict()


    reading = CSV.read("Input Data\\gen_cap.csv",DataFrame)
    reading = reading[reading[!,"Scenario"] .== scenario,:]
    reading = reading[reading[!,"Year"] .== year,:]
    reading = reading[reading[!,"Climate Year"] .== CY,:]

    for country in countries
        m.ext[:parameters][:technologies][country] = Dict()
        reading_country = reading[reading[!,"Node"] .== country,:]
        println(country)
        for technology in technologies[country]
            print(technology)
            capacity = reading_country[reading_country[!,"Generator_ID"] .== technology,:].Value
            #@assert(length(capacity) == 1)
            m.ext[:parameters][:technologies][country][technology] = sum(capacity)
        end
    end

    reading_lines = CSV.read("Input Data\\lines.csv",DataFrame)
    reading_lines = reading_lines[reading_lines[!,"Scenario"] .== scenario,:]
    reading_lines = reading_lines[reading_lines[!,"Climate Year"] .== CY,:]
    reading_lines = reading_lines[reading_lines[!,"Year"] .== year,:]

    #Initialize dicts
    for country in countries
        m.ext[:parameters][:connections][country] = Dict()
    end
    # Extract line capacities from data file
    for country in Set(reading_lines.Node1)
        reading_country = reading_lines[(reading_lines[!,"Node1"] .== country),:]
        for node_2 in Set(reading_country.Node2)
            capacity_imp = reading_country[(reading_country[!,"Node2"] .== node_2).&(reading_country[!,"Parameter"] .== "Import Capacity"),:].Value
            if (country == "BE00" && node_2 == "DE00")
                @show(reading_country[(reading_country[!,"Node2"] .== node_2).&(reading_country[!,"Parameter"] .== "Import Capacity"),:])
            end
            m.ext[:parameters][:connections][country][node_2] = abs.(capacity_imp)
            capacity_exp = reading_country[(reading_country[!,"Node2"] .== node_2).&(reading_country[!,"Parameter"] .== "Export Capacity"),:].Value
            m.ext[:parameters][:connections][node_2][country] = abs.(capacity_exp)
        end
        # reading_country = reading_lines[(reading_lines[!,"Node2"] .== country),:]
        # for node_2 in connections[country]
        #     capacity = reading_country[reading_country[!,"Node1"] .== node_2,:].Value
        #     m.ext[:parameters][:connections][country][node_2] = capacity
        # end
    end
    # Post check on line parameters to fill missing values to 0
    for node1 in keys(m.ext[:sets][:connections])
        #@show(node1)
        for node2 in m.ext[:sets][:connections][node1]
            #print(node2)
            #@assert(!(isempty(m.ext[:parameters][:connections][node1][node2])))
            if isempty(m.ext[:parameters][:connections][node1][node2])
                @show(node1,node2)
                m.ext[:parameters][:connections][node1][node2] = 0
            end
        end
    end
end

function process_time_series!(m::Model,scenario::String)
    countries = m.ext[:sets][:countries]

    m.ext[:timeseries] = Dict()
    m.ext[:timeseries][:demand] = Dict()

    scenario_dict = Dict("Distributed Energy" => "DE","Global Ambition" => "GA","National Trends" => "NT")
    filename = string(scenario_dict[scenario],"2040_Demand_CY1984.csv")
    demand_reading = CSV.read(joinpath("Input Data",filename),DataFrame)
    for country in countries
        m.ext[:timeseries][:demand][country] = demand_reading[!,country]
    end
end
##

function build_isolated_model!(m::Model,endtime,VOLL)
    technologies = m.ext[:sets][:technologies]
    countries =  m.ext[:sets][:countries]
    timesteps = collect(1:endtime)

    demand = m.ext[:timeseries][:demand]

    #Variables
    m.ext[:variables] = Dict()
    production = m.ext[:variables][:production] = @variable(m,[c= countries, tech=technologies[c],time=timesteps],base_name = "production")
    load_shedding =  m.ext[:variables][:load_shedding] = @variable(m,[c= countries,time=timesteps],base_name = "production")

    #Expressions
    m.ext[:expressions] = Dict()
    total_production_timestep = m.ext[:expressions][:total_production_timestep] =
        @expression(m, [c = countries, time = timesteps],
        sum(production[c,tech,time] for tech in technologies[c])
        )

    production_cost = m.ext[:expressions][:production_cost] =
        @expression(m, [c = countries, time = timesteps],
        sum(production[c,tech,time]*100 for tech in technologies[c])
        )
    load_shedding_cost = m.ext[:expressions][:load_shedding_cost] =
        @expression(m, [c = countries, time = timesteps],
        load_shedding[c,time]*VOLL
        )

    #Constraints
    m.ext[:constraints] = Dict()
    m.ext[:constraints][:demand_met] = @constraint(m,[c = countries, time = timesteps],
        total_production_timestep[c,time] + load_shedding[c,time]  == demand[c][time]
    )

    m.ext[:constraints][:production_capacity] = @constraint(m,[c = countries, tech = technologies[c],time = timesteps],
        production[c,tech,time] == 0
    )


    #Objective
    m.ext[:objective] = @objective(m,Min, sum(production_cost) + sum(load_shedding_cost))

end

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
     @expression(m, [c = countries, tech = technologies[c], time = timesteps], endtime/8760*production[c,tech,time]*variable_cost[c][tech])
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


using Gurobi


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



reading_lines = CSV.read("Input Data\\lines.csv",DataFrame)
reading_lines = reading_lines[reading_lines[!,"Scenario"] .== scenario,:]
reading_lines = reading_lines[reading_lines[!,"Climate Year"] .== CY,:]
reading_lines = reading_lines[reading_lines[!,"Year"] .== year,:]


country = "DE00"
other_country = "NL00"
reading_lines = reading_lines[reading_lines[!,"Node1"] .== country,:]
reading_lines = reading_lines[reading_lines[!,"Node2"] .== other_country,:]
reading_lines[reading_lines[!,"Parameter"] .== "Export Capacity",:].Value

##
m = Model(optimizer_with_attributes(Gurobi.Optimizer))
define_sets!(m,"Distributed Energy", 2040,1984)
process_parameters!(m,"Distributed Energy", 2040,1984)
process_time_series!(m,"Distributed Energy")
build_isolated_model!(m,5,1000)
optimize!(m)

JuMP.value.(m.ext[:variables][:load_shedding])
JuMP.value.(m.ext[:variables][:load_shedding]["CY00",1])
JuMP.value.(m.ext[:expressions][:load_shedding_cost]["CY00",1])
JuMP.value.(m.ext[:expressions][:total_production_timestep])
##
m.ext[:sets][:countries]
m.ext[:sets][:technologies]["FR00"]
m.ext[:sets][:dispatchable_technologies]["FR00"]

m.ext[:sets][:connections]
m.ext[:parameters][:technologies]["BE00"]
sum(m.ext[:parameters][:technologies]["BE00"][key] for key in keys(m.ext[:parameters][:technologies]["BE00"]))

m.ext[:sets][:connections]["BE00"]
m.ext[:sets][:connections]["DE00"]

m.ext[:parameters][:connections]
m.ext[:parameters][:connections]["DE00"]["FR00"]
m.ext[:parameters][:connections]["LUB1"]["BE00"]

m.ext[:timeseries]
##
#Check if all lines from sets are represented in parameters
for node1 in m.ext[:sets][:countries]
    ncs = length(m.ext[:sets][:connections][node1])
    ncp = length(m.ext[:parameters][:connections][node1])
    @assert(ncs == ncp)
end


#Check if every line has capacity
for node1 in keys(m.ext[:sets][:connections])
    @show(node1)
    for node2 in m.ext[:sets][:connections][node1]
        print(node2)
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
