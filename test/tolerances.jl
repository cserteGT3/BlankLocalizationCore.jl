@testset "PlanePlaneDistance: tolerancedistance" begin
    empty_plane = SimplePlane([0,0,0])

    machined_plane1 = SimplePlane([0,0,0])
    machined_plane2 = SimplePlane([5,6,7])

    mpoints = Point3[(13,9,7.1), (-100,70,6.9), (5000,-2,7.)]
    sm1 = SimpleMesh(mpoints, [connect((1,2,3))])
    mesh_plane1 = MeshPlane(sm1)

    pz1 = PartZero("testpz1", [0,0,0], [1 0 0;0 1 0;0 0 1])
    pz2 = PartZero("testpz2", [0,0,0], [0 0 1;0 1 0;0 1 0])

    # lf1 has machined_plane1 as machined feature
    lf1 = LocalizationFeature("t1", pz1, empty_plane, machined_plane1)
    # lf2 has machined_plane2 as machined feature
    lf2 = LocalizationFeature("tf1", pz1, empty_plane, machined_plane2)
    # lf3 has "wrong" z axis
    lf3 = LocalizationFeature("t3", pz2, empty_plane, empty_plane)
    # lf4 has both features a mesh, and "correct" part zero
    lf4 = LocalizationFeature("t4", pz1, mesh_plane1, mesh_plane1)
    
    # testing machined-machined distance
    # nominal, lower, upper, and note doesn't matter here
    t1 = LocalizationTolerance(lf1, BLC.MACHINED, lf2, BLC.MACHINED, PlanePlaneDistance(), 0, 0, 0, "")
    @test isapprox(toleranceddistance(t1), 7)

    # testing if not parallel part zeros throw error
    t2 = LocalizationTolerance(lf1, BLC.MACHINED, lf3, BLC.MACHINED, PlanePlaneDistance(), 0, 0, 0, "")
    @test_throws ErrorException toleranceddistance(t2)

    # testing IsFreeForm vs IsPrimitive
    # both MACHINED and ROUGH
    t3 = LocalizationTolerance(lf4, BLC.MACHINED, lf1, BLC.MACHINED, PlanePlaneDistance(), 0, 0, 0, "")
    t4 = LocalizationTolerance(lf4, BLC.ROUGH, lf1, BLC.MACHINED, PlanePlaneDistance(), 0, 0, 0, "")
    @test isapprox(toleranceddistance(t3), 7)
    @test isapprox(toleranceddistance(t4), 7)

    ## test if order of features doesn't matter
    t1_r = LocalizationTolerance(lf2, BLC.MACHINED, lf1, BLC.MACHINED, PlanePlaneDistance(), 0, 0, 0, "")
    @test isapprox(toleranceddistance(t1), toleranceddistance(t1_r))

    t2_r = LocalizationTolerance(lf3, BLC.MACHINED, lf1, BLC.MACHINED, PlanePlaneDistance(), 0, 0, 0, "")
    @test_throws ErrorException toleranceddistance(t2_r)

    t3_r = LocalizationTolerance(lf1, BLC.MACHINED, lf4, BLC.MACHINED, PlanePlaneDistance(), 0, 0, 0, "")
    t4_r = LocalizationTolerance(lf1, BLC.MACHINED, lf4, BLC.ROUGH, PlanePlaneDistance(), 0, 0, 0, "")
    @test isapprox(toleranceddistance(t3), toleranceddistance(t3_r))
    @test isapprox(toleranceddistance(t4), toleranceddistance(t4_r))
end