@testset "IsPrimitive geometries" begin
    sh = SimpleHole([0, 0, 0], 29)
    sp = SimplePlane([0, 0, 0], [0, 0, 1])

    @test featurepoint(sh) == [0, 0, 0]
    @test featureradius(sh) == 29
    @test featurepoint(sp) == [0, 0, 0]

    @test_throws MethodError featureradius(sp)
    @test_throws ErrorException surfacepoints(sp)
    @test_throws ErrorException surfacepoints(sh)
    @test_throws ErrorException filteredsurfacepoints(sp)
    @test_throws ErrorException filteredsurfacepoints(sh)
end
