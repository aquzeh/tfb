getgenv().firesignal = function(target, ...)
    local args = table.pack(...)
    local sig = target

    if typeof(target) == "Instance" then
        if target:IsA("RemoteEvent") then
            sig = target.OnClientEvent
        elseif target:IsA("BindableEvent") then
            sig = target.Event
        else
            sig = target.OnClientEvent or target.Event or target
        end
    end

    if typeof(sig) ~= "RBXScriptSignal" then
        return 0, {"fireclient: target is not RBXScriptSignal or not a supported Instance"}
    end

    local connections
    if type(getconnections) == "function" then
        local ok, res = pcall(getconnections, sig)
        if ok and type(res) == "table" and #res > 0 then
            connections = res
        else
            if typeof(target) == "Instance" then
                local ok2, res2 = pcall(getconnections, target)
                if ok2 and type(res2) == "table" and #res2 > 0 then
                    connections = res2
                end
            end
        end
    end

    if not connections or #connections == 0 then
        return 0, {"fireclient: no connections found (executor may not expose them or none exist on client)"}
    end

    local called = 0
    local errors = {}
    local seen = {}

    for _, conn in ipairs(connections) do
        if conn and not seen[conn] then
            seen[conn] = true
            local fn = conn.Function or conn.callback or conn.Callback or conn.func or conn.Func
            local enabled = true
            if conn.State ~= nil then enabled = conn.State end
            if conn.Connected ~= nil then enabled = conn.Connected end

            if type(fn) == "function" and enabled and fn ~= getgenv().firesignal then
                local ok, err = pcall(function()
                    fn(table.unpack(args, 1, args.n))
                end)
                if ok then
                    called = called + 1
                else
                    table.insert(errors, err)
                end
            end
        end
    end

    return called, errors
end