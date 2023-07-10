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

@testset "PlaneAxisDistance: tolerancedistance" begin
    # test error throwing -> should be addressed by #7
    machined_plane1 = SimplePlane([0,0,0])

    mpoints = Point3[(13,9,7.1), (-100,70,6.9), (5000,-2,7.)]
    sm1 = SimpleMesh(mpoints, [connect((1,2,3))])
    mesh_plane1 = MeshPlane(sm1)

    pz1_front = PartZero("testpz1", [0,0,0], [1 0 0;0 1 0;0 0 1])
    pz2_right = PartZero("testpz2", [10,10,10], [-1 0 0;0 0 1;0 1 0])

    # lf1 simple plane and simple plane
    lf1 = LocalizationFeature("t1", pz1_front, machined_plane1, machined_plane1)
    # lf2 simple plane and mash plane
    lf2 = LocalizationFeature("tf1", pz1_front, machined_plane1, mesh_plane1)

    t1_mr = LocalizationTolerance(lf1, BLC.ROUGH, lf2, BLC.MACHINED, PlaneAxisDistance(), 0, 0, 0, "")
    t1_rm = LocalizationTolerance(lf2, BLC.MACHINED, lf1, BLC.ROUGH, PlaneAxisDistance(), 0, 0, 0, "")
    @test_throws ErrorException toleranceddistance(t1_mr)
    @test_throws ErrorException toleranceddistance(t1_rm)

    # plane and hole test
    t1_mm = LocalizationTolerance(lf1, BLC.MACHINED, lf2, BLC.ROUGH, PlaneAxisDistance(), 0, 0, 0, "")
    @test_throws ErrorException toleranceddistance(t1_mm)

    ## test distance calculation
    sh1 = SimpleHole([10, 0, 0], 15)
    sh2 = SimpleHole([0, -10, 0], 15)
    empty_hole = SimpleHole([0,0,0], 0)

    pl1 = SimplePlane([15, 0, 0])
    pl2 = SimplePlane([0, 0, 15])
    empty_plane = SimplePlane([0,0,0])

    h1 = LocalizationFeature("fronth1", pz1_front, empty_hole, sh1)
    h2 = LocalizationFeature("fronth1", pz1_front, empty_hole, sh2)

    p1 = LocalizationFeature("rightp1", pz2_right, empty_plane, pl1)
    p2 = LocalizationFeature("rightp2", pz2_right, empty_plane, pl2)

    lt11 = LocalizationTolerance(p1, BLC.MACHINED, h1, BLC.MACHINED, PlaneAxisDistance(), 10, 10, 10, "")
    lt12 = LocalizationTolerance(p1, BLC.MACHINED, h2, BLC.MACHINED, PlaneAxisDistance(), 20, 20, 20, "")

    lt21 = LocalizationTolerance(p2, BLC.MACHINED, h1, BLC.MACHINED, PlaneAxisDistance(), 25, 25, 25, "")
    lt22 = LocalizationTolerance(p2, BLC.MACHINED, h2, BLC.MACHINED, PlaneAxisDistance(), 35, 35, 35, "")

    @test isapprox(toleranceddistance(lt11), 10)
    @test isapprox(toleranceddistance(lt12), 20)
    @test isapprox(toleranceddistance(lt21), 25)
    @test isapprox(toleranceddistance(lt22), 35)
end

@testset "AxisAxisDistance: tolerancedistance" begin
    ## test error throwing -> should be addressed by #7
    machined_plane1 = SimplePlane([0,0,0])

    mpoints = Point3[(13,9,7.1), (-100,70,6.9), (5000,-2,7.)]
    sm1 = SimpleMesh(mpoints, [connect((1,2,3))])
    mesh_plane1 = MeshPlane(sm1)

    # part zeros are different of the previous ones
    pz1_front = PartZero("frontpz1", [0,0,0], [0 0 1;1 0 0;0 1 0])
    pz2_right = PartZero("rightpz2", [10,10,10], [-1 0 0;0 0 1;0 1 0])

    # lf1 simple plane and simple plane
    lf1 = LocalizationFeature("t1", pz1_front, machined_plane1, machined_plane1)
    # lf2 simple plane and mesh plane
    lf2 = LocalizationFeature("tf1", pz1_front, machined_plane1, mesh_plane1)

    t1_mr = LocalizationTolerance(lf1, BLC.ROUGH, lf2, BLC.MACHINED, AxisAxisDistance(), 0, 0, 0, "")
    t1_rm = LocalizationTolerance(lf2, BLC.MACHINED, lf1, BLC.ROUGH, AxisAxisDistance(), 0, 0, 0, "")
    @test_throws ErrorException toleranceddistance(t1_mr)
    @test_throws ErrorException toleranceddistance(t1_rm)

    # plane and hole test
    t1_mm = LocalizationTolerance(lf1, BLC.MACHINED, lf2, BLC.ROUGH, AxisAxisDistance(), 0, 0, 0, "")
    @test_throws ErrorException toleranceddistance(t1_mm)

    ## test distance calculation

    sh1_machined = SimpleHole([10, 0, 0], 15)
    sh2_machined = SimpleHole([5, 10, 15], 15)
    sh1_rough = SimpleHole([0, 10, 0], 14.9)
    sh2_rough = SimpleHole([5, 25, 20], 14.9)

    fh1 = LocalizationFeature("fronth1", pz1_front, sh1_rough, sh1_machined)

    rh1 = LocalizationFeature("righth1", pz2_right, sh2_rough, sh2_machined)

    # all comibinations of rough-machined should be the same
    aat1 = LocalizationTolerance(fh1, BLC.MACHINED, rh1, BLC.MACHINED, AxisAxisDistance(), 20, 20, 20, "")
    aat2 = LocalizationTolerance(fh1, BLC.MACHINED, rh1, BLC.ROUGH, AxisAxisDistance(), 20, 20, 20, "")
    aat3 = LocalizationTolerance(fh1, BLC.ROUGH, rh1, BLC.MACHINED, AxisAxisDistance(), 20, 20, 20, "")
    aat4 = LocalizationTolerance(fh1, BLC.ROUGH, rh1, BLC.ROUGH, AxisAxisDistance(), 20, 20, 20, "")
    @test isapprox(toleranceddistance(aat1), 20)
    @test isapprox(toleranceddistance(aat2), 20)
    @test isapprox(toleranceddistance(aat3), 20)
    @test isapprox(toleranceddistance(aat4), 20)
end

@testset "AxisAxisConcentric: tolerancedistance" begin
    pz2_right = PartZero("rightpz2", [10,10,10], [-1 0 0;0 0 1;0 1 0])
    pz3_right = PartZero("rightpz3", [0,0,0], [-1 0 0;0 0 1;0 1 0])
    
    aac1_m = SimpleHole([0,0,19], 15)
    aac1_r = SimpleHole([10.1,28.9,10.1], 15)
    
    aac2_m = SimpleHole([-10, 10, 37], 15)
    aac2_r = SimpleHole([9, 36, 9], 15)
    
    # distance aac1_m -> aac1_r: sqrt(2)/10
    # distance aac1_m -> aac2_m: 0
    
    # distance aac2_m -> aac2_r: sqrt(2)
    
    aac_lf1 = LocalizationFeature("righth1", pz2_right, aac1_r, aac1_m)
    aac_lf2 = LocalizationFeature("righth2", pz3_right, aac2_r, aac2_m)
    
    aac1 = LocalizationTolerance(aac_lf1, BLC.MACHINED, aac_lf1, BLC.ROUGH, AxisAxisConcentric(), sqrt(2)/10, 0,0, "")
    aac2 = LocalizationTolerance(aac_lf1, BLC.MACHINED, aac_lf2, BLC.MACHINED, AxisAxisConcentric(), 0, 0,0, "")
    aac3 = LocalizationTolerance(aac_lf2, BLC.ROUGH, aac_lf2, BLC.MACHINED, AxisAxisConcentric(), sqrt(2), 0,0, "")
    
    @test isapprox(toleranceddistance(aac1), sqrt(2)/10)
    @test isapprox(toleranceddistance(aac2), 0)
    @test isapprox(toleranceddistance(aac3), sqrt(2))
end
