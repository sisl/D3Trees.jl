using D3Trees
using Base.Test

children = [[2,3], [], [4], []]
text = ["one", "2", "III", "four"]
t = D3Tree(children, text)

stringmime(MIME("text/html"), t)

inchrome(t)
