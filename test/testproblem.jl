@testset "simple mop" begin
    # this is the problem from the documentation:
    # https://csertegt3.github.io/BlankLocalizationCore.jl/stable/example/
    ## Part zero definitions

    pzf = PartZero("front", [0,0,0], hcat([0,1,0], [0,0,1], [1,0,0]))
    pzr = PartZero("right", [0,0,0], hcat([-1, 0, 0], [0, 0, 1], [0, 1, 0]))
    pzb = PartZero("back", [0,0,0], hcat([0, -1, 0], [0, 0, 1], [-1, 0, 0]))

    partzeros = [pzf, pzr, pzb]

    ## Machined geometry definitions

    fronthole_m = SimpleHole([0, 0, 0], 29)
    frontface_m = SimplePlane([0, 0, 0])

    righthole1_m = SimpleHole([16, 15, 0], 7.5)
    righthole2_m = SimpleHole([25, -16, 3], 9)
    righthole3_m = SimpleHole([60, 0, -3], 13.5)
    rightface1_m = SimplePlane([16, 15, 0])
    rightface2_m = SimplePlane([25, -16, 3])
    rightface3_m = SimplePlane([60, 0, -3])

    backhole1_m = SimpleHole([-14, 14, 0], 9)
    backhole2_m = SimpleHole([14, 14, 0], 9)
    backface1_m = SimplePlane([-14, 14, 0])
    backface2_m = SimplePlane([14, 14, 0])

    ## Rough geometry definitions

    fronthole_r = SimpleHole([82.5, 30, 40], 26)
    frontface_r = PlaneAndNormal([82.5, 30, 40], [1, 0, 0])

    righthole1_r = SimpleHole([66, 71.5, 55], 6)
    righthole2_r = SimpleHole([58, 74.5, 24], 4.905)
    righthole3_r = SimpleHole([21.5, 68.5, 40], 8)
    rightface1_r = PlaneAndNormal([66, 71.5, 55], [0, 1, 0])
    rightface2_r = PlaneAndNormal([58, 74.5, 24], [0, 1, 0])
    rightface3_r = PlaneAndNormal([21.5, 68.5, 40], [0, 1, 0])

    backhole1_r = SimpleHole([-3, 44, 53.9], 6.2)
    backhole2_r = SimpleHole([-3, 16.1, 54], 6.25)
    backface1_r = PlaneAndNormal([-3, 44, 54], [-1, 0, 0])
    backface2_r = PlaneAndNormal([-3, 16, 54], [-1, 0, 0])

    ## Geometry pairing and feature descriptors

    # Feature descriptors for each feature

    fd_fronthole = FeatureDescriptor("fronthole", pzf, true, true)
    fd_frontface = FeatureDescriptor("frontface", pzf, true, true)

    fd_righthole1 = FeatureDescriptor("righthole1", pzr, true, true)
    fd_righthole2 = FeatureDescriptor("righthole2", pzr, true, true)
    fd_righthole3 = FeatureDescriptor("righthole3", pzr, true, true)
    fd_rightface1 = FeatureDescriptor("rightface1", pzr, true, true)
    fd_rightface2 = FeatureDescriptor("rightface2", pzr, true, true)
    fd_rightface3 = FeatureDescriptor("rightface3", pzr, true, true)

    fd_backhole1 = FeatureDescriptor("backhole1", pzb, true, true)
    fd_backhole2 = FeatureDescriptor("backhole2", pzb, true, true)
    fd_backface1 = FeatureDescriptor("backface1", pzb, true, true)
    fd_backface2 = FeatureDescriptor("backface2", pzb, true, true)

    # Hole features

    holes = [HoleLocalizationFeature(fd_fronthole, fronthole_r, fronthole_m),
        HoleLocalizationFeature(fd_righthole1, righthole1_r, righthole1_m),
        HoleLocalizationFeature(fd_righthole2, righthole2_r, righthole2_m),
        HoleLocalizationFeature(fd_righthole3, righthole3_r, righthole3_m),
        HoleLocalizationFeature(fd_backhole1, backhole1_r, backhole1_m),
        HoleLocalizationFeature(fd_backhole2, backhole2_r, backhole2_m)
        ]

    # Face features
    planes = [PlaneLocalizationFeature(fd_frontface, frontface_r, frontface_m),
    PlaneLocalizationFeature(fd_rightface1, rightface1_r, rightface1_m),
    PlaneLocalizationFeature(fd_rightface2, rightface2_r, rightface2_m),
    PlaneLocalizationFeature(fd_rightface3, rightface3_r, rightface3_m),
    PlaneLocalizationFeature(fd_backface1, backface1_r, backface1_m),
    PlaneLocalizationFeature(fd_backface2, backface2_r, backface2_m)
    ]

    ## Tolerances

    xfunc(x) = x[1]
    yfunc(x) = x[2]
    zfunc(x) = x[3]

    tolerances = [Tolerance("rightface1", true, yfunc, "fronthole", true, 41, 40.7, 41.3, "1"),
    Tolerance("backhole1", true, yfunc, "fronthole", true, 14, 13.8, 14.2, "2"),
    Tolerance("fronthole", true, yfunc, "backhole2", true, 14, 13.8, 14.2, "3"),
    Tolerance("backhole1", true, zfunc, "fronthole", true, 14, 13.8, 14.2, "4"),
    Tolerance("backhole2", true, zfunc, "fronthole", true, 14, 13.8, 14.2, "5"),
    Tolerance("rightface3", true, yfunc, "fronthole", true, 38, 37.7, 38.3, "6"),
    Tolerance("rightface2", true, yfunc, "fronthole", true, 44, 43.7, 44.3, "7"),
    Tolerance("frontface", true, xfunc, "righthole3", true, 60, 59.7, 60.3, "8"),
    Tolerance("frontface", true, xfunc, "righthole2", true, 25, 24.8, 25.2, "9"),
    Tolerance("frontface", true, xfunc, "righthole1", true, 16, 15.8, 16.2, "10"),
    Tolerance("righthole1", true, zfunc, "fronthole", true, 15, 14.8, 15.2, "11"),
    Tolerance("fronthole", true, zfunc, "righthole2", true, 16, 15.8, 16.2, "12"),
    Tolerance("frontface", true, xfunc, "backface1", false, 85, 84.6, 85.4, "13"),
    Tolerance("frontface", true, xfunc, "backface2", false, 85, 84.6, 85.4, "14"),
    Tolerance("righthole3", true, zfunc, "fronthole", true, 0, -0.2, 0.2, "15")]

    ## Constructing and solving the optimization problem
    ## Constructing and solving the optimization problem
    pard = Dict("minAllowance"=>0.5, "OptimizeForToleranceCenter"=>true,
        "UseTolerances"=>true, "maxPlaneZAllowance"=>1)

    mop = MultiOperationProblem(partzeros, holes, planes, tolerances, pard)

    import Ipopt

    @test mop.opresult.status == "empty"
    @test BLC.getfeaturebyname(mop, "fronthole") === holes[1]
    @test BLC.getfeaturebyname(mop, "frontface") === planes[1]
    @test BLC.problemtype(mop) == :PrimitiveProblem

    optimizeproblem!(mop, Ipopt.Optimizer)
    @test mop.opresult.status == "LOCALLY_SOLVED"

    resallowance = minimumallowance(mop)
    tolerror = toleranceerror(mop)
    
    @test isapprox(resallowance.radial, 1.48846, atol=0.01)
    @test isapprox(resallowance.axial, 0.5, atol=0.01)
    # atol=0.01 -> toleranceerror returns in the 0-100% range
    @test isapprox(tolerror, 0, atol=0.01)

    # infeasible problem
    pard = Dict("minAllowance"=>0.5, "OptimizeForToleranceCenter"=>true,
        "UseTolerances"=>true, "maxPlaneZAllowance"=>0.1)
    
    setparameters!(mop, pard)
    optimizeproblem!(mop, Ipopt.Optimizer)
    @test mop.opresult.status == "LOCALLY_INFEASIBLE"
    @test mop.opresult.minallowance === NaN


end