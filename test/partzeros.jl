@testset "PartZero" begin
    pz1 = PartZero("pz1", [0,0,0], hcat([0,1,0], [0,0,1], [1,0,0]))
    pz2 = PartZero("pz", [0,0,0], hcat([0,1,0], [0,0,1], [1,0,0]))

    @test BLC.xaxis(pz1) == [0, 1, 0]
    @test BLC.yaxis(pz1) == [0, 0, 1]
    @test BLC.zaxis(pz1) == [1, 0, 0]

    M = BLC.getpartzeroHM(pz1)
    Mt = [0 0 1 0; 1 0 0 0; 0 1 0 0; 0 0 0 1]
    @test M == Mt

    @test inv(Mt) == BLC.getpartzeroinverseHM(pz1)
    @test inv(Mt) == BLC.inverthomtr(Mt)

    pz = BLC.getpartzerobyname([pz1, pz2], "pz")
    @test pz === pz2
end