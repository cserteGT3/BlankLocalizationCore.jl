@testset "IsPrimitive geometries" begin
    sh = SimpleHole([0, 0, 0], 29)
    sp = SimplePlane([0, 0, 0])

    @test featurepoint(sh) == [0, 0, 0]
    @test featureradius(sh) == 29
    @test featurepoint(sp) == [0, 0, 0]

    @test_throws MethodError featureradius(sp)
    @test_throws ErrorException surfacepoints(sp)
    @test_throws ErrorException surfacepoints(sh)
    @test_throws ErrorException filteredsurfacepoints(sp)
    @test_throws ErrorException filteredsurfacepoints(sh)

    pz1 = PartZero("pz1", [0, 0, 0], hcat([0, 1, 0], [0, 0, 1], [1, 0, 0]))
    sh_r = SimpleHole([82.5, 30, 40], 26)
    sp_r = PlaneAndNormal([82.5, 30, 40], [1, 0, 0])
    fd_sh = FeatureDescriptor("simple-hole", pz1, true, true)
    fd_sp = FeatureDescriptor("simple-plane", pz1, true, true)

    h1 = HoleLocalizationFeature(fd_sh, sh_r, sh)
    p1 = PlaneLocalizationFeature(fd_sp, sp_r, sp)

    @test BLC.getfeaturename(h1) == "simple-hole"
    @test BLC.getfeaturename(p1) == "simple-plane"
    @test BLC.getpartzero(h1) === BLC.getpartzero(p1) === pz1
    @test BLC.getpartzeroname(h1) == "pz1"
    @test BLC.hasrough(h1)
    @test BLC.hasrough(p1)
    @test BLC.hasmachined(h1)
    @test BLC.hasmachined(p1)

    @test BLC.getroughfeaturepoint(h1) == [82.5, 30, 40]
    @test BLC.getroughfeaturepoint(p1) == [82.5, 30, 40]
    @test BLC.getmachinedfeaturepoint(h1) == [0, 0, 0]
    @test BLC.getmachinedfeaturepoint(p1) == [0, 0, 0]
    @test BLC.getmachinedradius(h1) == 29
    @test_throws MethodError BLC.getmachinedradius(p1)
    @test BLC.getroughradius(h1) == 26
    @test_throws MethodError BLC.getroughradius(p1)

    @test_throws ErrorException BLC.getroughfilteredpoints(h1)
    @test_throws ErrorException BLC.getroughfilteredpoints(p1)

    @test BLC.getmachinedfeaturepointindatum(h1) == [0, 0, 0]
    @test BLC.getmachinedfeaturepointindatum(p1) == [0, 0, 0]
end
