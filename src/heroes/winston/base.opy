#!mainFile "../../main.opy"


globalvar ZapCharges = 1
globalvar ZapCooldown = createWorkshopSetting(int[0:20], "Winston", "Zap Cooldown time", 2, 0)
globalvar ZapChargeTime = createWorkshopSetting(float[0:10], "Winston", "Zap Charge time", 1, 0)
globalvar ZapDamage = createWorkshopSetting(int[0:500], "Winston", "Zap Damage", 50, 0)
globalvar ZapRange = createWorkshopSetting(float[0:500], "Winston", "Zap Range", 500, 0)
globalvar ZapRadius = createWorkshopSetting(float[0:2], "Winston", "Zap Projectile Size", 0.5, 0)
globalvar ZapHitboxArray
globalvar ZapLoop

playervar ZapChargeMeter
playervar DeletableHUD
playervar ZapHUDSpacer
playervar ZapEffects
playervar ZapHudProgress
playervar ZapHitPlayer
playervar p_ZapCharges


def CleanupWinston():
    @Name "[winston.del] Subroutine: Cleanup"
    
    waitUntil(eventPlayer.getCurrentHero() != evalOnce(eventPlayer.getCurrentHero()) or eventPlayer.getHeroOfDuplication() != evalOnce(eventPlayer.getHeroOfDuplication()), 9999)
    CleanupHealthPools()
    CleanupTexts()
    wait()
    eventPlayer.HeroActive = null


def InitialWinston():
    @Name "[winston.del] Subroutine: Initial"
    
    waitUntil(eventPlayer.HeroActive == null, 9999)
    if eventPlayer.HeroActive == Hero.WINSTON:
        return
    wait()
    eventPlayer.HeroActive = Hero.WINSTON
    #Character setup
    eventPlayer.addHealthPool(Health.NORMAL, 110.714 if eventPlayer.isUsingUltimate() else 75, true, true)
    eventPlayer.HeroHealthPools.append(getLastCreatedHealthPool())
    eventPlayer.addHealthPool(Health.ARMOR, 10.7, true, true)
    eventPlayer.HeroHealthPools.append(getLastCreatedHealthPool())
    eventPlayer.p_ZapCharges = ZapCharges
    hudSubheader(eventPlayer, " \n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", HudPosition.RIGHT, 20, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)
    eventPlayer.HeroTexts.append(getLastCreatedText())
    hudText(eventPlayer, ceil(ZapCooldown - eventPlayer.ZapChargeMeter) if eventPlayer.p_ZapCharges == 0 else iconString(Icon.BOLT), null, "{0}".format(buttonString(Button.SECONDARY_FIRE)), HudPosition.RIGHT, 21, Color.RED if eventPlayer.p_ZapCharges == 0 else Color.WHITE, Color.WHITE, Color.WHITE, HudReeval.VISIBILITY_SORT_ORDER_STRING_AND_COLOR, SpecVisibility.DEFAULT)
    eventPlayer.HeroTexts.append(getLastCreatedText())
    async(CleanupWinston, AsyncBehavior.NOOP)


rule "[winston.del] Initial":
    @Event eachPlayer
    @Hero winston
    
    InitialWinston()


rule "[winston.del] Initial (Duplication)":
    @Event eachPlayer
    @Hero echo
    @Condition eventPlayer.getHeroOfDuplication() == Hero.WINSTON
    
    InitialWinston()
