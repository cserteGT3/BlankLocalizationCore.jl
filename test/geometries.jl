@testset "IsPrimitive geometries" begin
    tpoints = [(0,0),(1,0),(1,1)]
    tconnec = [connect((1,2,3))]
    tmesh = SimpleMesh(tpoints, tconnec)
    cyl1 = Cylinder(15.0)

    pz1 = PartZero("pz1", [0,0,0], [1 0 0;0 1 0;0 0 1])

    # IsFreeForm, HOLELIKE
    r1 = RoughFeature("rh1", HOLELIKE, tmesh)
    @test GeometryStyle(r1) == IsFreeForm()
    @test isholelike(r1)
    @test_throws ErrorException featureradius(r1)
    @test_throws ErrorException featurepoint(r1)

    # IsPrimitive, HOLELIKE
    m1 = MachinedFeature("mh1", HOLELIKE, cyl1, pz1)
    @test GeometryStyle(m1) == IsPrimitive()
    @test isholelike(m1)
    @test featurepoint(m1) == Point3(0,0,1)
    @test featureradius(m1) == 15
    @test_throws ErrorException surfacepoints(m1)

    f1 = LocalizationFeature("h1", r1, m1)
    @test GeometryStyle(f1) == IsFreeForm()

    # IsPrimitive, PLANELIKE
    r2 = RoughFeature("rp1", PLANELIKE, Plane(Point3(0,0,0), Vec3(0,0,1)))
    @test GeometryStyle(r2) == IsPrimitive()
    @test isplanelike(r2)
    @test featurepoint(r2) == Point3(0,0,0)
    @test_throws ErrorException featureradius(r2)
    @test_throws ErrorException surfacepoints(r2)

    # IsPrimitive, PLANELIKE
    m2 = MachinedFeature("mp1", PLANELIKE, Plane(Point3(0,0,0), Vec3(0,0,1)), pz1)
    @test GeometryStyle(m2) == IsPrimitive()
    @test isplanelike(m2)
    @test featurepoint(m2) == Point3(0,0,0)
    @test_throws ErrorException featureradius(m2)
    @test_throws ErrorException surfacepoints(m2)

    f2 = LocalizationFeature("p1", r2, m2)
    @test GeometryStyle(f2) == IsPrimitive()
end
