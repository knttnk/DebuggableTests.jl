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
end

"""
    TestSet(name, tests, editing_testset_index)

editing_testset_indexは，現在編集中のテストセットのインデックス．
0のときは，現在編集中のテストセットは自分自身．
-1のときは，現在編集中のテストセットは自分や子ではない．
"""
mutable struct TestSet
    name::String
    tests::Vector{Union{TestSet,Test}}
    editing_testset_index::Int64
end

const global_testset = TestSet("global", [], 0)

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

function end_testset()
    c = current_testset()
    p = parent_testset()
    c.editing_testset_index = -1
    p.editing_testset_index = 0
end

function new_testset(name::String)
    c = current_testset()
    n = length(c.tests)
    c.editing_testset_index = n + 1
    append!(c.tests, [TestSet(name, [], 0)])
end

function new_test(name::String, val)
    c = current_testset()
    append!(
        c.tests,
        [Test(name, val === true ? Passed : Failed)],
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

    return quote
        $(new_testset)($(name))
        $(esc(block))
        $(end_testset)()
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

    return quote
        local val = $(esc(block))
        $(new_test)($(name), val)
    end
end

function show_test_result()
    global global_testset
    function show_test_result_impl(testset::TestSet, nest::Int, indent::String="  ")
        for test in testset.tests
            if test isa Test
                println("$(repeat(indent, nest))$(test.name) : $(test.status)")
            elseif test isa TestSet
                println("$(repeat(indent, nest))$(test.name)")
                show_test_result_impl(test, nest + 1, indent)
            end
        end
    end
    show_test_result_impl(global_testset, 0)
end

end