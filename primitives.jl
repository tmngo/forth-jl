# Start defining a new word.
function startdef(env::Environment)
    if isempty(env.tokens)
        throw(ErrorException("A name is required after ':' to create a definition."))
    end
    env.latest = pop!(env.tokens)
    env.tempword = Word(Union{Symbol, Int}[])
    env.mode = COMPILE::Mode
end


# Finish defining a new word.
function finishdef(env::Environment)
    if env.latest == Symbol()
        return
    end
    validatedef(env)
    env.dictionary[env.latest] = env.tempword
    env.latest = Symbol()
    env.mode = INTERPRET::Mode
end


# Swap the two values at the top of the stack.
function swap(env::Environment)
    try
        b = pop!(env.stack)
        a = pop!(env.stack)
        push!(env.stack, b)
        push!(env.stack, a)
    catch
        throw(ErrorException("Cannot pop from empty stack."))
    end
end


# Prints the current contents of the word dictionary.
function printdict(env::Environment)
    for key in keys(env.dictionary)
        print("$(rpad(key, 12, ' '))")
        value = env.dictionary[key].value
        if value isa Function
            print("Primitive")
        else
            for elem in value
                print("$(elem) ")
            end
        end
        println()
    end
end

# Simple binary and unary operations.
add(env::Environment)       = binaryop(env, (a, b) -> a + b)
sub(env::Environment)       = binaryop(env, (a, b) -> a - b)
mul(env::Environment)       = binaryop(env, (a, b) -> a * b)
div(env::Environment)       = binaryop(env, (a, b) -> a / b)
mod(env::Environment)       = binaryop(env, (a, b) -> a % b)
equals(env::Environment)    = binaryop(env, (a, b) -> (a == b ? -1 : 0))
less(env::Environment)      = binaryop(env, (a, b) -> (a < b ? -1 : 0))
greater(env::Environment)   = binaryop(env, (a, b) -> (a > b ? -1 : 0))
and(env::Environment)       = binaryop(env, (a, b) -> a & b)
or(env::Environment)        = binaryop(env, (a, b) -> a | b)
invert(env::Environment)    = unaryop(env, a -> ~a)
dot(env::Environment)       = unaryop(env, a -> (print(a, " ")))
emit(env::Environment)      = unaryop(env, a -> (isvalid(Char, a) && print(Char(a))))


# Helper function for defining words that pop one operand from the stack.
function unaryop(env::Environment, op::Function)
    try
        a = pop!(env.stack)
        result = op(a)
        if result !== nothing
            push!(env.stack, result)
        end
    catch
        throw(ErrorException("Cannot pop from empty stack."))
    end
end


# Helper function for defining words that pop two operands from the stack.
function binaryop(env::Environment, op::Function)
    try
        b = pop!(env.stack)
        a = pop!(env.stack)
        push!(env.stack, op(a, b))
    catch
        throw(ErrorException("Cannot pop from empty stack."))
    end
end


# Check if the current definition has balanced if/then and do/loop constructs.
function validatedef(env::Environment)
    if_balance = 0
    do_balance = 0
    for name in env.tempword.value
        if name == :if 
            if_balance += 1
        elseif name == :else
            if if_balance == 0
                throw(ErrorException("Unexpected 'else'."))
            end
        elseif name == :then
            if_balance -= 1
            if if_balance < 0
                throw(ErrorException("Unexpected 'then'."))
            end
        elseif name == :do 
            do_balance += 1
        elseif name == :loop
            do_balance -= 1
            if do_balance < 0
                throw(ErrorException("Unexpected 'loop'."))
            end
        end
    end
    if if_balance > 0
        throw(ErrorException("Missing 'then' after 'if'."))
    elseif do_balance > 0
        throw(ErrorException("Missing 'loop' after 'do'."))
    end
end