# D3Trees

[![Build Status](https://travis-ci.org/sisl/D3Trees.jl.svg?branch=master)](https://travis-ci.org/sisl/D3Trees.jl)

[![Coverage Status](https://coveralls.io/repos/sisl/D3Trees.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/sisl/D3Trees.jl?branch=master)

[![codecov.io](http://codecov.io/github/sisl/D3Trees.jl/coverage.svg?branch=master)](http://codecov.io/github/sisl/D3Trees.jl?branch=master)

Flexible interactive visualization for large trees using [D3.js](d3js.org).

## Installation

```julia
Pkg.clone("https://github.com/sisl/D3Trees.jl.git")
```

## Usage

```julia
children = [[2,3], [], [4], []]
t = D3Tree(children)

inchrome(t)
```
or, for more options,
```julia
children = [[2,3], [], [4], []]
text = ["one\n(second line)", "2", "III", "four"]
style = ["", "fill:red", "r:14", "opacity:0.7"]
link_style = ["", "stroke:blue", "", "stroke-width:10px"]
tooltip = ["pops", "up", "on", "hover"]
t = D3Tree(children,
           text=text,
           style=style,
           tooltip=tooltip,
           link_style=link_style)

inchrome(t)
```

or, see [examples/hello.ipynb](https://nbviewer.jupyter.org/github/sisl/D3Trees.jl/blob/master/examples/hello.ipynb)

Many more features to come.
