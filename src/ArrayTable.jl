mutable struct ArrayTable{N, C <: AbstractDictionary{Symbol, <:AbstractArray{<:Any, N}}, I} <: AbstractArray{NamedTuple, N}
    columns::C
    indices::I

    # Inner constructor, to compare axes?
    @inline function ArrayTable{N, C, I}(columns::C, indices::I) where {N, C, I}
        @boundscheck check_indices_match(columns, indices)
        new(columns, indices)
    end
end

function check_indices_match(columns, indices)
    foreach(pairs(columns)) do (name, column)
        if keys(column) !== indices
            # TODO the keys print in long form...
            throw(DimensionMismatch("Column $name has indices $(keys(column)), which does not match table indices $indices"))
        end
    end
end

Tables.columns(t::ArrayTable) = getfield(t, :columns)
_indices(t::ArrayTable) = getfield(t, :indices)

columnnames(t::ArrayTable) = keys(columns(t))

ArrayTable() = ArrayTable(Dictionary{Symbol, Vector}(), LinearIndices{1,Tuple{Base.OneTo(0)}})
@propagate_inbounds function ArrayTable(cols::AbstractDictionary{Symbol, <:AbstractArray{<:Any, N}}) where N
    if isempty(cols)
        if N == 1
            inds = LinearIndices((0,))
        else
            inds = CartesianIndices(ntuple(_ -> 0, Val(N)))
        end
    else
        inds = keys(first(cols))
    end
    return ArrayTable{N, typeof(cols), typeof(inds)}(cols, inds)
end

Base.IndexStyle(::ArrayTable{<:Any, <:Any, <:LinearIndices}) = Base.IndexLinear()
Base.IndexStyle(::ArrayTable{<:Any, <:Any, <:CartesianIndices}) = Base.IndexCartesian()

Base.axes(t::ArrayTable) = axes(_indices(t))
Base.keys(t::ArrayTable) = keys(_indices(t))
Base.length(t::ArrayTable) = length(_indices(t))
Base.size(t::ArrayTable) = length(_indices(t))

@propagate_inbounds Base.getproperty(t::ArrayTable, s::Symbol) = getindex(columns(t), s)

@inline function Base.getindex(t::ArrayTable{<:Any, C, <:LinearIndices}, i::Integer) where {C}
    @boundscheck checkbounds(_indices(t), i)
    return ArrayTableRow{Any, C, typeof(i)}(columns(t), i)
end

@inline function Base.getindex(t::ArrayTable{<:Any, C, <:CartesianIndices}, i::Integer...) where {C}
    @boundscheck checkbounds(_indices(t), i)
    return ArrayTableRow{Any, C, typeof(i)}(columns(t), i)
end

struct ArrayTableRow{T, C <: AbstractDictionary{Symbol, <:AbstractArray}, I} <: AbstractDictionary{Symbol, T}
    columns::C
    index::I
end

_columns(r::ArrayTableRow) = getfield(r, :columns)
_index(r::ArrayTableRow) = getfield(r, :index)

Dictionaries.keys(r::ArrayTableRow) = keys(_columns(r))

Dictionaries.isinsertable(::ArrayTableRow) = false
Dictionaries.issettable(r) = true # Should depend on array type and can vary from column to column?

Dictionaries.isassigned(r::ArrayTableRow, s::Symbol) = isassigned(_columns(r), s)
@propagate_inbounds function Dictionaries.getindex(r::ArrayTableRow, s::Symbol)
    c = _columns(r)[s]
    return @inbounds c[_index(r)]
end
@propagate_inbounds function Dictionaries.setindex!(r::ArrayTableRow{T}, value::T, s::Symbol) where {T}
    c = _columns(r)[s]
    return @inbounds c[_index(r)] = value
end

Dictionaries.istokenizable(r::ArrayTableRow) = istokenizable(_columns(r))
Dictionaries.gettoken(r::ArrayTableRow, s::Symbol) = gettoken(_columns(r), s)
Dictionaries.istokenassigned(r::ArrayTableRow, token) = istokenassigned(_columns(r), token)
Dictionaries.gettokenvalue(r::ArrayTableRow, token) = @inbounds gettokenvalue(_columns(r), token)[_index(r)]
Dictionaries.settokenvalue!(r::ArrayTableRow{T}, token, value::T) where {T} = @inbounds gettokenvalue(_columns(r), token)[_index(r)] = value

# show

Base.show(io::IO, ::MIME"text/plain", t::ArrayTable) = showtable(io, t)
Base.show(io::IO, t::ArrayTable) = showtable(io, t)

# Support Vector / deque interface (mutable-length vectors)

function Base.empty!(t::ArrayTable)
    map(empty!, columns(t))
    return t
end

function Base.pop!(t::ArrayTable)
    return map(pop!, columns(t))
end

function Base.push!(t::ArrayTable, v::AbstractDictionary)
    map(push!, columns(t), v)
    return t
end

function Base.append!(t::ArrayTable, t2::AbstractVector)
    map(append!, columns(t), columns(t2))
    return t
end

function Base.popfirst!(t::ArrayTable)
    return map(popfirst!, columns(t))
end

function Base.pushfirst!(t::ArrayTable, v::AbstractDictionary)
    map(pushfirst!, columns(t), v)
    return t
end

function Base.prepend!(t::ArrayTable, t2::AbstractVector)
    map(prepend!, columns(t), columns(t2))
    return t
end

function Base.deleteat!(t::ArrayTable, i)
    map(col -> deleteat!(col, i), columns(t))
    return t
end

function Base.insert!(t::ArrayTable, i::Integer, v::AbstractDictionary)
    map((col, val) -> insert!(col, i, val), columns(t), v)
    return t
end

function Base.splice!(t::ArrayTable, inds::Integer)
    return map(col -> splice!(col, inds), columns(t))
end

function Base.splice!(t::ArrayTable, inds::AbstractArray)
    cols = map(col -> splice!(col, inds), columns(t))
    return @inbounds ArrayTable(cols)
end

function Base.splice!(t::ArrayTable, inds::Integer, ins::AbstractDictionary)
    return map((col, vals) -> splice!(col, inds, vals), columns(t), ins)
end

function Base.splice!(t::ArrayTable, inds::AbstractArray, ins::AbstractDictionary)
    cols = map((col, vals) -> splice!(col, inds, vals), columns(t), ins)
    return @inbounds ArrayTable(cols)
end

function Base.splice!(t::ArrayTable, inds::Integer, ins::AbstractVector)
    return map((col, vals) -> splice!(col, inds, vals), columns(t), columns(ins))
end

function Base.splice!(t::ArrayTable, inds::AbstractArray, ins::AbstractVector)
    cols = map((col, vals) -> splice!(col, inds, vals), columns(t), columns(ins))
    return @inbounds ArrayTable(cols)
end
