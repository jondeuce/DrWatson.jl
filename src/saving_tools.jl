export current_commit, tag!, @tag!
export dict_list, dict_list_count

"""
    current_commit(gitpath = projectdir()) -> commit
Return the current active commit id of the Git repository present
in `gitpath`, which by default is the project gitpath. If the repository
is dirty when this function is called the string will end
with `"_dirty"`.

Return `nothing` if `gitpath` is not a Git repository.

See also [`tag!`](@ref).

## Examples
```julia
julia> current_commit()
"96df587e45b29e7a46348a3d780db1f85f41de04"

julia> current_commit(path_to_dirty_repo)
"3bf684c6a115e3dce484b7f200b66d3ced8b0832_dirty"
```
"""
function current_commit(gitpath = projectdir())
    # Here we test if the gitpath is a git repository.
    try
        repo = LibGit2.GitRepo(gitpath)
    catch er
        @warn "The current project directory is not a Git repository, "*
        "returning `nothing` instead of the commit id."
        return nothing
    end
    # then we return the current commit
    repo = LibGit2.GitRepo(gitpath)
    c = string(LibGit2.head_oid(repo))
    if LibGit2.isdirty(repo)
        @warn "The Git repository is dirty! Adding appropriate comment to "*
        "commit id..."
        return c*"_dirty"
    end
    return c
end

"""
    tag!(d::Dict, gitpath = projectdir()) -> d
Tag `d` by adding an extra field `commit` which will have as value
the [`current_commit`](@ref) of the repository at `gitpath` (by default
the project's gitpath). Do nothing if a key `commit` already exists or
if the Git repository is not found.

Notice that if `String` is not a subtype of the value type of `d` then
a new dictionary is created and returned. Otherwise the operation
is inplace (and the dictionary is returned again).

## Examples
```julia
julia> d = Dict(:x => 3, :y => 4)
Dict{Symbol,Int64} with 2 entries:
  :y => 4
  :x => 3

julia> tag!(d)
Dict{Symbol,Any} with 3 entries:
  :y      => 4
  :commit => "96df587e45b29e7a46348a3d780db1f85f41de04"
  :x      => 3
```
"""
function tag!(d::Dict{K, T}, gitpath = projectdir(), source = nothing) where {K, T}

    c = current_commit(gitpath)
    c === nothing && return d
    if haskey(d, K("commit"))
        @warn "The dictionary already has a key named `commit`. We won't "*
        "add any Git information."
        return d
    end
    if String <: T
        d[K("commit")] = c
    else
        d = Dict{K, promote_type(T, String)}(d)
        d[K("commit")] = c
    end
    if source != nothing
        if haskey(d, K("script"))
            @warn "The dictionary already has a key named `script`. We won't "*
            "overwrite it with the script name."
        else
            d[K("script")] = relpath(sourcename(source), gitpath)
        end
    end
    return d
end

sourcename(s) = string(s)
sourcename(s::LineNumberNode) = string(s.file)*"#"*string(s.line)

"""
    @tag!(d, gitpath = projectdir()) -> d
Do the same as [`tag!`](@ref) but also add another field `script` that has
the path of the script that called `@tag!`, relative with respect to `gitpath`.
The saved string ends with `#line_number`, which indicates the line number
within the script that `@tag!` was called at.

## Examples
```julia
julia> d = Dict(:x => 3)Dict{Symbol,Int64} with 1 entry:
  :x => 3

julia> @tag!(d) # running from a script or inline evaluation of Juno
Dict{Symbol,Any} with 3 entries:
  :commit => "618b72bc0936404ab6a4dd8d15385868b8299d68"
  :script => "test\\stools_tests.jl#10"
  :x      => 3
```
"""
macro tag!(d, gitpath = projectdir())
    s = QuoteNode(__source__)
    :(tag!($(esc(d)), $(esc(gitpath)), $s))
end

"""
    dict_list(c::Dict)
Expand the dictionary `c` into a vector of dictionaries.
Each entry has a unique combination from the product of the `Vector`
values of the dictionary while the non-`Vector` values are kept constant
for all possibilities. The keys of the entries are the same.

Whether the values of `c` are iterable or not is of no concern;
the function considers as "iterable" only subtypes of `Vector`.

Use the function [`dict_list_count`](@ref) to get the number of
dictionaries that `dict_list` will produce.

## Examples
```julia
julia> c = Dict(:a => [1, 2], :b => 4);

julia> dict_list(c)
3-element Array{Dict{Symbol,Int64},1}:
 Dict(:a=>1,:b=>4)
 Dict(:a=>2,:b=>4)

julia> c[:model] = "linear"; c[:run] = ["bi", "tri"];

julia> dict_list(c)
4-element Array{Dict{Symbol,Any},1}:
 Dict(:a=>1,:b=>4,:run=>"bi",:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"bi",:model=>"linear")
 Dict(:a=>1,:b=>4,:run=>"tri",:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"tri",:model=>"linear")

julia> c[:e] = [[1, 2], [3, 5]];

julia> dict_list(c)
8-element Array{Dict{Symbol,Any},1}:
 Dict(:a=>1,:b=>4,:run=>"bi",:e=>[1, 2],:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"bi",:e=>[1, 2],:model=>"linear")
 Dict(:a=>1,:b=>4,:run=>"tri",:e=>[1, 2],:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"tri",:e=>[1, 2],:model=>"linear")
 Dict(:a=>1,:b=>4,:run=>"bi",:e=>[3, 5],:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"bi",:e=>[3, 5],:model=>"linear")
 Dict(:a=>1,:b=>4,:run=>"tri",:e=>[3, 5],:model=>"linear")
 Dict(:a=>2,:b=>4,:run=>"tri",:e=>[3, 5],:model=>"linear")
```
"""
function dict_list(c::Dict)
    iterable_fields = filter(k -> typeof(c[k]) <: Vector, keys(c))
    non_iterables = setdiff(keys(c), iterable_fields)

    iterable_dict = Dict(iterable_fields .=> getindex.(Ref(c), iterable_fields))
    non_iterable_dict = Dict(non_iterables .=> getindex.(Ref(c), non_iterables))

    vec(
        map(Iterators.product(values(iterable_dict)...)) do vals
            dd = Dict(keys(iterable_dict) .=> vals)
            if isempty(non_iterable_dict)
                dd
            elseif isempty(iterable_dict)
                non_iterable_dict
            else
                merge(non_iterable_dict, dd)
            end
        end
    )
end

"""
    dict_list_count(c) -> N
Return the number of dictionaries that will be created by
calling `dict_list(c)`.
"""
function dict_list_count(c)
    iterable_fields = filter(k -> typeof(c[k]) <: Vector, keys(c))
    prod(length(c[i]) for i in iterable_fields)
end

# function ntuple_list(c)
#     iterable_fields = filter(k -> typeof(c[k]) <: Vector, collect(keys(c)))
#     non_iterables = setdiff(keys(c), iterable_fields)
#
#     iterable_vals = Tuple(collect((typeof(c[i]) for i in iterable_fields)))
#     iterable_tuple = NamedTuple{tuple(iterable_fields), iterable_vals}
#
#     Dict(iterable_fields .=> getindex.(Ref(c), iterable_fields))
#     non_iterable_tuple = Dict(
#         non_iterables .=> getindex.(Ref(c), non_iterables))
#
#     vec(
#         map(Iterators.product(values(iterable_dict)...)) do vals
#             dd = Dict(keys(iterable_dict) .=> vals)
#             merge(non_iterable_dict, dd)
#         end
#     )
# end
