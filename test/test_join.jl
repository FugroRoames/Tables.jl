@testset "Join" begin

#@test TypedTables.testjoin(1, 1) == true
#@test TypedTables.testjoin(1, 2) == false
#@test TypedTables.dojoin(1, 1) == 1

#@test join(@row(A::Int64=1, B::Float64=2.0), @row(A::Int64=1, B::Float64=2.0)) === Nullable{Row{@index(A::Int64, B::Float64), Tuple{Int64, Float64}}}(@row(A::Int64=1, B::Float64=2.0))
#@test isnull(join(@row(A::Int64=1, B::Float64=2.0), @row(A::Int64=2, B::Float64=4.0)))
#@test join(@row(A::Int64=1, B::Float64=2.0), @row(B::Float64=2.0, C::Bool=true)) === Nullable{Row{@index(B::Float64, A::Int64, C::Bool), Tuple{Float64, Int64, Bool}}}(@row(B::Float64=2.0, A::Int64=1, C::Bool=true))

@test join(@Table(A=[1,2,3], B=[2.0,4.0,6.0]), @Table(B=[2.0,4.0,5.0,7.0], C=[true,false,true,false])) == @Table(B=[2.0,4.0], A=[1,2], C=[true,false])

end
