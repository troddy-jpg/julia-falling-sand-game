import Pkg


Pkg.add("Match")
Pkg.add("Colors")
Pkg.add("GameZero")

using GameZero
rungame("falling_sand.jl")