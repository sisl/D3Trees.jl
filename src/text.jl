function shownode(io::IO, node, depth::Int, item_prefix::String, prefix::String)
    buf = PipeBuffer()
    printnode(buf, node)
    for (i, line) in enumerate(eachline(buf, keep=true))
        if i == 1
            print(io, item_prefix*line)
        else
            print(io, prefix*line)
        end
    end
    if depth <= 0
        println(io, " ($(n_children(node)) children)")
    else
        println(io)
        n = n_children(node)
        for (i, c) in enumerate(children(node))
            if i < n
                shownode(io, c, depth-1, prefix*"├──", prefix*"│  ")
            else # last one
                shownode(io, c, depth-1, prefix*"└──", prefix*"   ")
            end
        end
    end
end
