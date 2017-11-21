CONFIGFILE=os.getenv("ASCIIART_CONFIG") or "render-asciiart-filter.config"
local config = {}
local configfile,err = loadfile(CONFIGFILE, "t", config)
if configfile then
   configfile() -- load the config
else
   io.stderr:write(err)
end

local outputdir=io.open("rendered","r")
if outputdir~=nil then
    io.close(outputdir)
else
    os.execute("mkdir rendered")
end

LIBDIR=os.getenv("ASCIIART_LIBDIR") or "lib"

local renderer = {
    ditaa = function(text, attrs)
        if attrs[1] then
            attrs = attrs[1][2]
        else
            attrs = config.ditaa.defaultargs or ""
        end
        params = {"-jar", LIBDIR .. "/ditaa.jar"}
        for w in attrs:gmatch("%S+") do
            table.insert(params, w)
        end
        table.insert(params, "-")
        table.insert(params, "-")
        -- local param_s=table.concat(params, " ")
        -- io.stderr:write("param str: " .. param_s .. "\n")
        -- io.stderr:write("param sha1: " .. pandoc.sha1(param_s) .. "\n")
        -- return pandoc.pipe("java", params, text)
        return {"java", params, text}
    end,
    plantuml = function(text, attrs)
        if attrs[1] then
            attrs = attrs[1][2]
        else
            attrs = config.plantuml.defaultargs or ""
        end
        params = {"-jar", LIBDIR .. "/plantuml.jar", "-tpng", "-p", "-Sbackgroundcolor=transparent"}
        for w in attrs:gmatch("%S+") do
            table.insert(params, w)
        end
        return {"java", params, text}
    end,
    dot = function(text, attrs)
        if attrs[1] then
            attrs = attrs[1][2]
        else
            attrs = config.dot.defaultargs or ""
        end
        params = {"-Tpng"}
        for w in attrs:gmatch("%S+") do
            table.insert(params, w)
        end
        return {"dot", params, text}
    end,
    qr = function(text, attrs)
        if attrs[1] then
            attrs = attrs[1][2]
        else
            attrs = config.qr.defaultargs or ""
        end
        params = {"-o", "-"}
        for w in attrs:gmatch("%S+") do
            table.insert(params, w)
        end
        return {"qrencode", params, text}
    end,
}

images = {}

function Pandoc(blocks)
    local pfile = io.popen('ls -a rendered/*.png')
    for fname in pfile:lines() do
        if not images[fname] then
            io.stderr:write("removing obsolete '" .. fname .. "'\n")
            os.remove(fname)
        end
    end
    pfile:close()

    return nil
end


function CodeBlock(elem, attr)
    for format, render_cmd in pairs(renderer) do
        if elem.classes[1] == format then
            local filetype = "png"
            local mimetype = "image/png"
            local cmd=render_cmd(elem.text, elem.attributes or {})
            local fname = "rendered/" .. format .. "-" .. pandoc.sha1(cmd[1] .. table.concat(cmd[2], " ") .. cmd[3]) .. "." .. filetype
            local data = nil

            local f=io.open(fname,"rb")
            if f~=nil then
                io.stderr:write("cached " .. format .. " rendering found: '" .. fname .. "'\n")
                data = f:read("*all")
                f:close()
            else
                io.stderr:write("rendering " .. format .. ": '" .. fname .. "'\n")
                data = pandoc.pipe(cmd[1], cmd[2], cmd[3])
                local f=io.open(fname, "wb")
                f:write(data)
                f:close()
            end
            images[fname] = true
            pandoc.mediabag.insert(fname, mimetype, data)
            return pandoc.Para{ pandoc.Image({pandoc.Str("rendered")}, fname) }
        end
    end
end

return {{CodeBlock = CodeBlock}, {Pandoc=Pandoc}}
