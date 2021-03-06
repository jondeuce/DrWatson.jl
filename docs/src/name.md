# Naming Simulations
Here we overview functionality that helps you quickly produce containers of parameters and name them using a consistent and intuitive naming scheme.

## Naming Schemes

A robust naming scheme allows you to create quick names for simulations, create lists of simulations, check existing simulations, etc. More importantly it allows you to easily create simulation-based names **consistently** and **deterministically**.

This is what the function [`savename`](@ref) does. Of course, you don't have to use it only for using names to save files. You could use it for anything that fits you (like e.g. adding identifiers to tabular data).

```@docs
savename
@dict
@strdict
@ntuple
```

Notice that this naming scheme integrates perfectly with Parameters.jl.

Two convenience functions are also provided to easily switch between named tuples and dictionaries:
```@docs
ntuple2dict
dict2ntuple
```

## Customizing `savename`
You can customize [`savename`](@ref) for your own Types. For example you could make it so that it only uses some specific keys instead of all of them, only specific types, or you could make it access data in a different way (maybe even loading files!). You can even make it have
a custom `prefix`!

To do that you may extend the following functions:
```@docs
DrWatson.allaccess
DrWatson.access
DrWatson.default_allowed
DrWatson.default_prefix
```

See [Real World Examples](@ref) for an example of customizing `savename`.
