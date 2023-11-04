
# using DebuggableTests  # change here like this
include("../src/DebuggableTests.jl")
using .DebuggableTests

# You can set breakpoints in the following code.
# You can also use the debugger in the test code.

@testset "Tests.jl" begin
    a = 2
    @testset "success" begin
        @testset "simple" begin
            @test "bool" true
            @test true
        end
        @test "with variables" a == 2
    end
    @testset "fail" begin
        @testset "simple" begin
            @test "bool" false
            @test false
        end
        @test "with variables" a == 3
    end
    @testset "error" begin
        @testset "simple" begin
            sin()  # MethodError
        end
        @test "with variables" error("simple error in test")
    end
end

show_test_result()