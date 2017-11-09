function CodeBlock(elem)
    local renderer = {
        ditaa = function(text)
            return pandoc.pipe("java", {"-jar", "lib/ditaa.jar", "-", "-"}, text)
        end,
        plantuml = function(text)
            return pandoc.pipe("java", {"-jar", "lib/plantuml.jar", "-tpng", "-p", "-Sbackgroundcolor=transparent"}, text)
        end,
        dot = function(text)
            return pandoc.pipe("dot", {"-Tpng"}, text)
        end,
    }
    for format, render_fun in pairs(renderer) do
        if elem.classes[1] == format then
            local filetype = "png"
            local mimetype = "image/png"
            local fname = "rendered/" .. format .. "-" .. pandoc.sha1(elem.text) .. "." .. filetype
            local data = nil

            local f=io.open(fname,"rb")
            if f~=nil then
                io.stderr:write("cached " .. format .. " rendering found!\n")
                data = f:read("*all")
                f:close()
            else
                io.stderr:write("rendering " .. format .. "!\n")
                data = render_fun(elem.text)
                local f=io.open(fname, "wb")
                f:write(data)
                f:close()
            end
            pandoc.mediabag.insert(fname, mimetype, data)
            return pandoc.Para{ pandoc.Image({pandoc.Str("rendered")}, fname) }
        end
    end
end
