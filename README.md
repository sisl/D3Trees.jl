# D3Trees

[![Build Status](https://travis-ci.org/sisl/D3Trees.jl.svg?branch=master)](https://travis-ci.org/sisl/D3Trees.jl)
[![Coverage Status](https://coveralls.io/repos/sisl/D3Trees.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/sisl/D3Trees.jl?branch=master)
[![codecov.io](http://codecov.io/github/sisl/D3Trees.jl/coverage.svg?branch=master)](http://codecov.io/github/sisl/D3Trees.jl?branch=master)

Flexible interactive visualization for large trees using [D3.js](d3js.org).

## Installation

```julia
Pkg.add("D3Trees")
```
or
```julia
Pkg.clone("https://github.com/sisl/D3Trees.jl.git")
```

## Usage

The structure of a D3Tree is specified with *lists of children for each node* stored in a `Vector` of `Int` `Vector`s. For example
```julia
D3Tree([[2,3], [], [4], []])
```
creates a tree with four nodes. Nodes 2 and 3 are children of node 1, and node 4 is the only child of node 3. Nodes 2 and 4 are childless.

In an IJulia notebook, the tree will automatically be displayed using D3.js. To get an interactive display in a chrome browser from the repl or a script, you can use the `inchrome` function. The `blink` function can also open it in a standalone window using the `Blink.jl` package.
```julia
children = [[2,3], [4,5], [6,7], [8,9], [1], [], [], [], []]
t = D3Tree(children)

inchrome(t)
```
By clicking on the nodes, you can expand it to look like this:
![Tree](img/tree.png)

Optional arguments control other aspects of the style (use `julia> ?D3Tree` for a complete list), for example
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
           link_style=link_style,
           title="My Tree",
           init_expanded=true)

inchrome(t)
```
will yield

![Expanded tree with style](img/styled_tree.png)

or, see [examples/hello.ipynb](https://nbviewer.jupyter.org/github/sisl/D3Trees.jl/blob/master/examples/hello.ipynb)

## Browser compatibility

This package works best in the Google chrome or chromium browser.
