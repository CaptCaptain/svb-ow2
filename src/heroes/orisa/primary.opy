#!mainFile "../../main.opy"


def OrisaDecreaseMovementPenalty():
    @Name "[orisa.del] Subroutine: Decrease Primary Fire Movement Speed Penalty"

    _objectVariable_2[([player for player in ActiveModifications if _objectVariable_0[player] == eventPlayer.OrisaMoveSpeedID])[0]] = 120
    waitUntil(not eventPlayer.isFiringPrimaryFire(), 9999)
    _objectVariable_2[([player for player in ActiveModifications if _objectVariable_0[player] == eventPlayer.OrisaMoveSpeedID])[0]] = 100


rule "[orisa.del] Decrease Primary Fire Movement Speed Penalty":
    @Event eachPlayer
    @Hero orisa
    @Condition eventPlayer.isFiringPrimaryFire() == true

    OrisaDecreaseMovementPenalty()


rule "[orisa.del] Decrease Primary Fire Movement Speed Penalty (Duplicate)":
    @Event eachPlayer
    @Hero echo
    @Condition eventPlayer.getHeroOfDuplication() == Hero.ORISA
    @Condition eventPlayer.isFiringPrimaryFire() == true
    
    OrisaDecreaseMovementPenalty()
