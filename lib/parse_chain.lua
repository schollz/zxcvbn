local operator = {}
-- operator["^"]={4,1,function(a,b) return a^b end}
operator["*"] = {3, -1, function(a, b)
    return a .. "*" .. b
end}
-- operator["/"]={3,-1,function(a,b) return a/b end}
operator["+"] = {1, -1, function(a, b)
    return a .. "+" .. b
end}
-- operator["-"]={1,-1,function(a,b) return a-b end}

local argument_seperator = ","

function string.fields(s)
    local t = {}
    for w in s:gmatch("%S+") do
        table.insert(t, w)
    end
    return t
end

local function tabprint(s)
    for i, v in ipairs(s) do
        print(i, v)
    end
end

local function splitExpr(expr)
    local oper = {"%+", "%-", "%*", "%/", "%^", "%(", "%)", "%w+"}
    for _, o in ipairs(oper) do
        expr = expr:gsub(o, " %1 ")
    end
    local out = expr:gsub("%s+", " "):gsub("^%s", ""):gsub("%s$", "")
    return string.fields(out)
end

local function toRPN(expr)
    local rpn_out = {}
    local rpn_stack = {}

    local expr = splitExpr(expr)

    if #expr == 0 then
        error("invalid expression")
    end

    local pos = 0
    local token = ""
    while pos < #expr do
        pos = pos + 1
        token = expr[pos]

        -- If the token is a number, then add it to the output
        if tonumber(token) then
            -- If the token is a function argument separator
            table.insert(rpn_out, token)
        elseif token == argument_seperator then
            while true do
                local stack_token = table.remove(rpn_stack)
                if stack_token == "(" then
                    table.insert(rpn_stack, "(")
                    break
                else
                    table.insert(rpn_out, stack_token)
                    if #rpn_stack == 0 then
                        error("expected ( before argument separator")
                    end
                end
            end
        elseif operator[token] then
            -- If the token is a left parenthesis, then push it onto the stack.
            local o1 = operator[token]
            while true do
                local stack_token = rpn_stack[#rpn_stack]
                if not stack_token then
                    break
                end
                local o2 = operator[stack_token]
                if o2 and ((o1[2] == -1 and o1[1] <= o2[1]) or (o1[2] == 1 and o1[1] < o2[1])) then
                    table.insert(rpn_out, table.remove(rpn_stack))
                else
                    break
                end
            end
            table.insert(rpn_stack, token)
        elseif token == "(" then
            table.insert(rpn_stack, "(")
        elseif token == ")" then
            -- must be a variable
            local stack_token = ""

            while true do
                stack_token = table.remove(rpn_stack)
                if stack_token == "(" then
                    break
                else
                    table.insert(rpn_out, stack_token)
                    if #rpn_stack == 0 then
                        error("mismatched parentheses")
                    end
                end
            end
        else
            table.insert(rpn_out, token)
        end
    end

    for i = #rpn_stack, 1, -1 do
        token = rpn_stack[i]
        if token == "(" or token == ")" then
            error("mismatched parentheses")
        else
            table.insert(rpn_out, token)
        end
    end

    return rpn_out
end

local stack = {}
local function push(a)
    table.insert(stack, 1, a)
end
local function pop()
    if #stack == 0 then
        return nil
    end
    return table.remove(stack, 1)
end

local function writeStack()
    for i = #stack, 1, -1 do
        io.write(stack[i], " ")
    end
    print()
end

local function operate(a)
    local s
    if a == "+" then
        -- io.write(a.."\tadd\t");writeStack()
        local b = pop()
        local c = pop()
        push(b .. " " .. c)
    elseif a == "-" then
        -- io.write(a.."\tsub\t");writeStack()
        s = pop()
        push(pop() - s)
    elseif a == "*" then
        -- io.write(a.."\tmul\t");writeStack()
        -- elseif a=="/" then
        --   s=pop();push(pop()/s)
        -- io.write(a.."\tdiv\t");writeStack()
        -- elseif a=="^" then
        --   s=pop();push(pop()^s)
        -- io.write(a.."\tpow\t");writeStack()
        -- elseif a=="%" then
        --   s=pop();push(pop()%s)
        -- io.write(a.."\tmod\t");writeStack()
        local b = pop()
        local c = pop()
        if tonumber(b) then
            push(string.rep(c .. " ", b))
        elseif tonumber(c) then
            push(string.rep(b .. " ", c))
        end
    else
        -- io.write(a.."\tpush\t");writeStack()
        push(a)
    end
end

local function calc(s)
    local t, a = "", ""
    -- print("\nINPUT","OP","STACK")
    for i = 1, #s do
        a = s:sub(i, i)
        if a == " " then
            operate(t)
            t = ""
        else
            t = t .. a
        end
    end
    if a ~= "" then
        operate(a)
    end
    return pop()
end

local function full_calc(s)
    local rpn = table.concat(toRPN(s), " ")
    return calc(rpn)
end

local function lazyString(s)
    local a = string.fields(s)
    local b = {}
    for i = 1, #a - 1 do
        local last_c = string.sub(a[i], #a[i])
        local first_c = string.sub(a[i + 1], 1, 1)
        table.insert(b, a[i])
        if last_c ~= "*" and first_c ~= "*" then
            table.insert(b, "+")
        end
    end
    table.insert(b, a[#a])
    return table.concat(splitExpr(table.concat(b, " ")), " ")
end

function parse_chain(s)
    local a = ""
    local _, err =
        pcall(
            function()
                a = full_calc(lazyString(s))
            end
        )
    return string.fields(string.reverse(a)), err
end


return parse_chain