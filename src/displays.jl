function blink(t::D3Tree)
    w = Window()
    str = stringmime(MIME("text/html"), t)
    # println(str)
    body!(w, str)
    return w
end

function inchrome(t::D3Tree)
    fname = joinpath(mktempdir(), "tree.html")
    open(fname, "w") do f
        show(f, MIME("text/html"), t)
    end
    if Sys.iswindows()
        run(`cmd /C start chrome "$fname"`)
    elseif Sys.isapple()
        run(`open -a "Google Chrome" $fname`)
    else
        run(`google-chrome $fname`)
    end
end

"""
    inbrowser(t::D3Tree, browsername::String)

Open an html document with the D3Tree in a browser with a platform-specific command.
"""
function inbrowser(t::D3Tree, browsername::String)
    if Sys.iswindows()
        inbrowser(t, `cmd /C start $browsername`)
    elseif Sys.isapple()
        inbrowser(t, `open -a $browsername`)
    else
        inbrowser(t, `$browsername`)
    end
end

"""
    inbrowser(t::D3Tree, command::Cmd)

Open an html document with the D3Tree in a program launched with the specified command.
"""
function inbrowser(t::D3Tree, command::Cmd)
    fname = joinpath(mktempdir(), "tree.html")
    open(fname, "w") do f
        show(f, MIME("text/html"), t)
    end
    run(`$command $fname`)
end
