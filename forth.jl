module Forth

include("types.jl")
include("primitives.jl")


function main()
    env = Environment(Dict{Symbol, Word}(
        # Defining words.
        :(:)        => Word(env -> startdef(env)),
        Symbol(";") => Word(env -> finishdef(env), immediate=true), 
        # Symbol() is needed instead of :() to parse correctly.
        :if         => Word(defonly=true),
        :else       => Word(defonly=true),
        :then       => Word(defonly=true),
        :do         => Word(defonly=true),
        :i          => Word(defonly=true),
        :loop       => Word(defonly=true),

        # Arithmetic.
        :(+)        => Word(env -> add(env)),
        :(-)        => Word(env -> sub(env)),
        :(*)        => Word(env -> mul(env)),
        :(/)        => Word(env -> div(env)),
        :mod        => Word(env -> mod(env)),
        
        # Logic.
        :(=)        => Word(env -> equals(env)),
        :(<)        => Word(env -> less(env)),
        :(>)        => Word(env -> greater(env)),
        :and        => Word(env -> and(env)),
        :or         => Word(env -> or(env)),
        :invert     => Word(env -> invert(env)),
        
        # Stack operations.
        :dup        => Word(env -> push!(env.stack, env.stack[end])),
        :drop       => Word(env -> pop!(env.stack)),
        :swap       => Word(env -> swap(env)),
        
        # Output.
        :(.)        => Word(env -> dot(env)),
        :cr         => Word(env -> println()),
        :emit       => Word(env -> emit(env)),

        # Debugging.
        Symbol(".d") => Word(env -> printdict(env)),
        Symbol(".s") => Word(env -> print(env.stack, " ")),

        # Predefined words can be added here, or in 'core.4th'.
        Symbol("0=") => Word(Union{Symbol, Int}[0, :(=)]),
    ))
        
    runfile(env, "./examples/core.4th")

    if length(ARGS) == 0
        runprompt(env)
    elseif length(ARGS) == 1
        runfile(env, ARGS[1])
    else
        println("Usage: julia forth.jl [script]");
        exit()
    end
end


# Run code from a file at the given path.
function runfile(env::Environment, path::String)
    try
        run(env, read(path, String))
    catch e
        if e isa ErrorException
            # Print a red error message.
            println("\n\033[1;31mERROR: $(e.msg)\033[0m")
        else
            throw(e)
        end
    end
end


# Start an interactive prompt.
function runprompt(env::Environment)
    while true
        # Print a green '>' and read from stdin.
        print("\033[1;32m", ">", "\033[0m ")
        line = try 
            readline()
        catch
            println("Unable to read line.")
            break
        end
        if line == ""
            break
        end
        try
            # Move cursor to end of previous line, and set color to gray.
            print("\33[F\33[$(length(line) + 4)C", "\033[1;30m")
            run(env, line)
            # Print a green 'ok'.
            println("\033[1;32m", " ok", "\033[0m")
        catch e
            if e isa ErrorException
                # Print a red error message.
                println("\n\033[1;31m", "ERROR: $(e.msg)", "\033[0m")
            end
        end
    end
end


# Parse and interpret a string of code.
function run(env::Environment, source::String)
    # Split the source into strings delimited by whitespace.
    lexemes = split(source)
    for i in length(lexemes):-1:1
        push!(env.tokens, Symbol(lexemes[i]))
    end

    while !isempty(env.tokens)
        token = pop!(env.tokens)
        parseresult::Union{Int, Nothing} = parsenumber(token)

        if haskey(env.dictionary, token)
            # Interpret and compile defined words.
            word = env.dictionary[token]
            if env.mode == INTERPRET::Mode || env.dictionary[token].immediate
                interpret(env, token)
            else
                push!(env.tempword.value, token)
            end
        elseif parseresult isa Int
            # Interpret and compile numeric literals.
            if env.mode == INTERPRET::Mode
                push!(env.stack, parseresult)
            else
                push!(env.tempword.value, parseresult)
            end
        else
            throw(ErrorException("The word “$(token)” is undefined."))
        end
    end
end


# Return an integer if the given token can be parsed as one, otherwise return nothing.
function parsenumber(token::Symbol)::Union{Int, Nothing}
    return tryparse(Int, string(token))
end


# Execute the word associated with the given token.
function interpret(env::Environment, token::Symbol)
    word::Union{Word, Nothing} = get(env.dictionary, token, nothing)
    if word.defonly || (word.immediate && env.mode == INTERPRET::Mode)
        throw(ErrorException("The word “$(token)” can only be used in word definitions."))
    end

    code = word.value
    if typeof(code) <: Function
        # Primitive word.
        code(env)
    elseif typeof(code) <: AbstractArray
        # User-defined word.
        i = 1
        loop_iter = []
        do_indices = []
        loop_ends = []

        while i <= length(code)
            if code[i] isa Int
                push!(env.stack, code[i])
                i += 1
            elseif code[i] == :if 
                if pop!(env.stack) != 0
                    # Continue to body of if.
                    i += 1
                else
                    # Go to command after 'then' or 'else'.
                    i = findnext(xi -> (xi == :then || xi == :else), code, i) + 1
                end
            elseif code[i] == :else
                # Finished body of if, go to command after 'then'.
                i = findnext(xi -> (xi == :then), code, i) + 1
            elseif code[i] == :then
                # Finished body of if, go to command after 'then'.
                i += 1
            elseif code[i] == :do
                push!(do_indices, i)
                push!(loop_iter, pop!(env.stack))
                push!(loop_ends, pop!(env.stack))
                i += 1
            elseif code[i] == :loop
                loop_iter[end] += 1
                if loop_iter[end] < loop_ends[end]
                    i = do_indices[end] + 1
                else
                    pop!(loop_iter)
                    pop!(loop_ends)
                    pop!(do_indices)
                    i += 1
                end
            elseif code[i] == :i
                push!(env.stack, loop_iter[end])
                i += 1
            else
                interpret(env, code[i])
                i += 1
            end
        end
    end
end


end


Forth.main()