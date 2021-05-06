@enum Mode COMPILE INTERPRET


struct Word
    value::Union{Function, Vector{Union{Symbol, Int}}}
    immediate::Bool
    defonly::Bool
end


function Word(value::Union{Function, Vector{Union{Symbol, Int}}}; 
        immediate::Bool=false, defonly::Bool=false)
    return Word(value, immediate, defonly)
end


function Word(; immediate::Bool=false, defonly::Bool=false)
    return Word((env) -> (), immediate, defonly)
end


mutable struct Environment
    dictionary::Dict{Symbol, Word}
    stack::Vector{Int}
    tokens::Vector{Symbol}
    latest::Symbol
    tempword::Word
    mode::Mode
end


function Environment(dictionary::Dict{Symbol, Word})
    return Environment(dictionary, [], [], Symbol(), 
            Word(Union{Symbol, Int}[]), INTERPRET::Mode)
end