module DebuggableTests

export @testset, @test, @mytime, show_test_result
import Base

@enum TestStatus begin
    Passed
    Failed
    Errored
end

struct Test
    name::String
    status::TestStatus
    location::String
end

"""
    TestSet(name, tests, editing_testset_index)

editing_testset_indexは，現在編集中のテストセットのインデックス．
0のときは，現在編集中のテストセットは自分自身．
-1のときは，現在編集中のテストセットは自分や子ではない．
"""
@kwdef mutable struct TestSet
    name::String
    tests::Vector{Union{TestSet,Test}}
    editing_testset_index::Int64
    error = nothing
    location::String = ""
end

const global_testset = TestSet(
    name="global",
    tests=[],
    editing_testset_index=0
)

function children(ts::TestSet)::Vector{Union{TestSet,Test}}
    children_list = Vector{Union{TestSet,Test}}()
    for test in ts.tests
        if test isa TestSet
            push!(children_list, test)
            children_list = vcat(children_list, children(test))
        else
            push!(children_list, test)
        end
    end
    return children_list
end

"""
    parent_testset()

current_testsetの親のテストセットを取得する．
"""
function parent_testset()::Union{TestSet,Nothing}
    global global_testset
    if global_testset.editing_testset_index == 0
        # global_testsetが編集中なので，親はいない
        return nothing
    end
    t::TestSet = global_testset
    while true
        child_of_t = t.tests[t.editing_testset_index]
        if child_of_t.editing_testset_index == 0
            # tの子供を編集中なので，tが親
            return t
        end
        t = child_of_t
    end
end

function current_testset()::TestSet
    global global_testset
    p = parent_testset()
    if isnothing(p)
        return global_testset
    else
        return p.tests[p.editing_testset_index]
    end
end

function end_testset(error=nothing)
    c = current_testset()
    p = parent_testset()
    c.error = error
    c.editing_testset_index = -1
    p.editing_testset_index = 0
end

function new_testset(name::String, location::String)
    c = current_testset()
    n = length(c.tests)
    c.editing_testset_index = n + 1
    append!(
        c.tests,
        [TestSet(
            name=name,
            tests=[],
            editing_testset_index=0,
            location=location,
        )]
    )
end

function new_test(name::String, val, location::String="")
    c = current_testset()
    append!(
        c.tests,
        [Test(name, val === true ? Passed : Failed, location)],
    )
end

macro testset(exs...)
    if length(exs) == 1
        local name = "unnamed testset"
        local block = exs[1]
    else
        local name = exs[1]
        local block = exs[2]
    end
    local location = "$(__source__.file):$(__source__.line)"

    return quote
        $(new_testset)($(name), $(location))
        local e
        try
            $(esc(block))
        catch e
            local l = $(location)
            printstyled(e, color=:red, bold=true)
            printstyled(
                "\n  @ $(l)\n",
                color=:light_black,
            )

            $(end_testset)(e)
        else
            $(end_testset)()
        end
    end
end

macro test(exs...)
    global current_testset
    if length(exs) == 1
        local name = "unnamed test"
        local block = exs[1]
    else
        local name = exs[1]
        local block = exs[2]
    end
    local location = "$(__source__.file):$(__source__.line)"

    return quote
        local val = $(esc(block))
        $(new_test)($(name), val, $(location))
    end
end

function show_test_result()
    global global_testset
    function show_test_result_impl(testset::TestSet, nest::Int, indent::String="  ")
        for test in testset.tests
            __testname = "$(repeat(indent, nest))$(test.name)"
            function print_location()
                space = repeat(" ", length(__testname))
                printstyled(
                    " $space @ $(test.location)\n",
                    color=:light_black,
                )
            end
            if test isa Test
                printstyled("$__testname: ", color=:light_black)
                color = test.status == Passed ? :green : :red
                printstyled("$(test.status)\n", color=color)
                if test.status == Failed || test.status == Errored
                    print_location()
                end
            elseif test isa TestSet
                printstyled("$__testname", bold=true)
                if isnothing(test.error)
                    print("\n")
                    show_test_result_impl(test, nest + 1, indent)
                else
                    print(": ")
                    printstyled(
                        "$(test.error)\n",
                        color=:red,
                        bold=true,
                    )
                    print_location()
                    show_test_result_impl(test, nest + 1, indent)
                end
            end
        end
    end
    show_test_result_impl(global_testset, 0)
end

end
