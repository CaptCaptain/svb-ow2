#!mainFile "../../main.opy"

globalvar AvalancheRadius
globalvar AvalancheDuration
globalvar AvalancheMaxSpeed
globalvar AvalancheEnabled
globalvar AvalancheDamagePerTick
globalvar AvalancheDamageExplosion
globalvar AvalancheTurnable
globalvar AvalancheTurnSpeed


playervar AvalancheEffects
playervar AvalancheSpeed
playervar AvalancheCurrentRadius
playervar AvalancheFacingDirection
playervar AvalancheFinalPosition
playervar PlayersInAvalanche
playervar AvalancheTimer


subroutine SetAvalancheCamera
subroutine ChaseAvalancheSpeed
subroutine ChaseAvalancheRadius
subroutine ClearAvalanche
subroutine ExplodeAvalanche
subroutine ExplodePlayersInAvalanche

subroutine DeployAvalanche


rule "Initialise Avalanche":
  AvalancheEnabled = createWorkshopSetting(bool, "Mei - Avalanche ability (Ultimate)", "Enable Avalanche instead of regular Ultimate", true, 0)
  AvalancheTurnable = createWorkshopSetting(bool, "Mei - Avalanche ability (Ultimate)", "Allow steering during Avalanche", true, 2)
  AvalancheTurnSpeed = createWorkshopSetting(int[10:500], "Mei - Avalanche ability (Ultimate)", "Turn Speed (if enabled)", 200, 3)
  AvalancheRadius = createWorkshopSetting(float[1:5], "Mei - Avalanche ability (Ultimate)", "Avalanche Radius", 3, 4)
  AvalancheDuration = createWorkshopSetting(float[1:5], "Mei - Avalanche ability (Ultimate)", "Avalanche Duration", 3, 5)
  AvalancheMaxSpeed = createWorkshopSetting(int[100:400], "Mei - Avalanche ability (Ultimate)", "Avalanche max speed", 300, 6)
  AvalancheDamagePerTick = createWorkshopSetting(float[0:10], "Mei - Avalanche ability (Ultimate)", "Damage per tick while players are attached", 1.5, 7)
  AvalancheDamageExplosion = createWorkshopSetting(float[0:500], "Mei - Avalanche ability (Ultimate)", "Damage on explode", 50, 8)


rule "Avalanche Progress Bar HUD element":
  @Event eachPlayer
  @Hero mei
  @Condition AvalancheEnabled == true
  
  progressBarHud([i for i in eventPlayer if eventPlayer.AvalancheTimer], 100 / AvalancheDuration * eventPlayer.AvalancheTimer, "", HudPosition.TOP, 10, Color.AQUA, Color.AQUA, ProgressHudReeval.VISIBILITY_VALUES_AND_COLOR, SpecVisibility.DEFAULT)
  #New lines to push the progress bar down
  hudSubheader([i for i in eventPlayer if eventPlayer.AvalancheTimer], " \n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", HudPosition.TOP, 9, Color.WHITE, HudReeval.VISIBILITY_AND_STRING, SpecVisibility.DEFAULT)


rule "Disable original Ultimate":
  @Event eachPlayer
  @Hero mei
  @Condition AvalancheEnabled == true
  
  eventPlayer.disallowButton(Button.ULTIMATE)

rule "Disable original Ultimate (Echo)":
  @Event eachPlayer
  @Hero echo
  @Condition eventPlayer.getHeroOfDuplication() == Hero.MEI
  @Condition AvalancheEnabled == true
  
  eventPlayer.disallowButton(Button.ULTIMATE)

def DeployAvalanche():
  @Name "[mei/avalanche.opy] Subroutine: Deploy Avalanche"

  if AvalancheEnabled == false: return
  if eventPlayer.isAlive() == false: return
  if eventPlayer.isUsingAbility1() == true: return
  if eventPlayer.AvalancheTimer == true: return
  if (eventPlayer.hasStatusEffect(Status.HACKED) or eventPlayer.hasStatusEffect(Status.KNOCKED_DOWN) or eventPlayer.hasStatusEffect(Status.ASLEEP) or eventPlayer.hasStatusEffect(Status.FROZEN) or eventPlayer.hasStatusEffect(Status.STUNNED) or eventPlayer.isDead()): return

  eventPlayer.disallowButton(Button.ABILITY_1)
  eventPlayer.disallowButton(Button.ABILITY_2)
  eventPlayer.disallowButton(Button.PRIMARY_FIRE)
  eventPlayer.disallowButton(Button.SECONDARY_FIRE)
  eventPlayer.disallowButton(Button.CROUCH)

  eventPlayer.cancelPrimaryAction()

  #Set timer and chase it down
  eventPlayer.AvalancheTimer = AvalancheDuration
  chase(eventPlayer.AvalancheTimer, 0, duration=AvalancheDuration, ChaseReeval.DESTINATION_AND_DURATION)
  #Communicate, for fun
  eventPlayer.communicate(Comms.INCOMING)
  waitUntil(eventPlayer.hero != evalOnce(eventPlayer.hero), AvalancheDuration + 0.5)
  eventPlayer.setUltCharge(0)
  eventPlayer.AvalancheTimer = 0


rule "Player presses Ultimate":
  @Event eachPlayer
  @Hero mei
  @Condition eventPlayer.isHoldingButton(Button.ULTIMATE) == true

  async(DeployAvalanche, AsyncBehavior.RESTART)

rule "Player presses Ultimate (Echo)":
  @Event eachPlayer
  @Hero echo
  @Condition eventPlayer.getHeroOfDuplication() == Hero.MEI
  @Condition eventPlayer.isHoldingButton(Button.ULTIMATE) == true

  async(DeployAvalanche, AsyncBehavior.RESTART)

rule "Player is using Avalanche":
  @Event eachPlayer
  @Condition eventPlayer.AvalancheTimer == true
  
  #Set initial facing direction
  eventPlayer.AvalancheFacingDirection = eventPlayer.getFacingDirection()
  eventPlayer.PlayersInAvalanche = []
  #Set player to "Phased Out" so they don't collide with others and can't be hit, as well as clearing all debuffs
  eventPlayer.setStatusEffect(null, Status.PHASED_OUT, AvalancheDuration)
  #Call relevant rules
  async(ChaseAvalancheSpeed, AsyncBehavior.NOOP)
  async(ChaseAvalancheRadius, AsyncBehavior.NOOP)
  SetAvalancheCamera()
  #Start forcing the player forwards
  eventPlayer.startForcingThrottle(1, 1, 0, 0, 0, 0.01 if AvalancheTurnable else 0)
  #Create a bunch of effects that make up the ability
  eventPlayer.AvalancheEffects = []
  #Spheres
  createEffect(getAllPlayers(), Effect.SPHERE, Color.WHITE, updateEveryTick(eventPlayer), eventPlayer.AvalancheCurrentRadius, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
  eventPlayer.AvalancheEffects = eventPlayer.AvalancheEffects.concat(getLastCreatedEntity())
  createEffect(getAllPlayers(), Effect.SPHERE, eventPlayer.getTeam(), eventPlayer, eventPlayer.AvalancheCurrentRadius, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
  eventPlayer.AvalancheEffects = eventPlayer.AvalancheEffects.concat(getLastCreatedEntity())
  #Sparkles
  createEffect(getAllPlayers(), Effect.SPARKLES, Color.WHITE, updateEveryTick(eventPlayer.getPosition()), eventPlayer.AvalancheCurrentRadius * 2, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
  eventPlayer.AvalancheEffects = eventPlayer.AvalancheEffects.concat(getLastCreatedEntity())
  createEffect(getAllPlayers(), Effect.SPARKLES, eventPlayer.getTeam(), updateEveryTick(eventPlayer.getPosition()), eventPlayer.AvalancheCurrentRadius * 2, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
  eventPlayer.AvalancheEffects = eventPlayer.AvalancheEffects.concat(getLastCreatedEntity())
  #Clouds
  createEffect(getAllPlayers(), Effect.CLOUD, Color.WHITE, updateEveryTick(eventPlayer.getPosition()), eventPlayer.AvalancheCurrentRadius * 2, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
  eventPlayer.AvalancheEffects = eventPlayer.AvalancheEffects.concat(getLastCreatedEntity())
  createEffect(getAllPlayers(), Effect.CLOUD, eventPlayer.getTeam(), updateEveryTick(eventPlayer.getPosition()), eventPlayer.AvalancheCurrentRadius * 2, EffectReeval.VISIBILITY_POSITION_AND_RADIUS)
  eventPlayer.AvalancheEffects = eventPlayer.AvalancheEffects.concat(getLastCreatedEntity())
  #Wait before clearing avalanche
  waitUntil(eventPlayer.AvalancheTimer == false, AvalancheDuration)
  ClearAvalanche()


def SetAvalancheCamera():
  @Name "Subroutine - Set Avalanche camera"
  
  #Force the player to third person
  eventPlayer.startCamera(raycast(eventPlayer.getEyePosition() + Vector.UP * 0.5, eventPlayer.getEyePosition() + Vector.UP * 0.5 + eventPlayer.getFacingDirection() * -5, getAllPlayers(), eventPlayer, true).getHitPosition(), raycast(eventPlayer.getEyePosition(), eventPlayer.getEyePosition() + eventPlayer.getFacingDirection() * 20, null, eventPlayer, false).getHitPosition(), 60)


def ChaseAvalancheSpeed():
  @Name "Subroutine - Chase Avalanche Speed"
  
  #Gradually increase the player speed
  for eventPlayer.AvalancheSpeed in range(100, AvalancheMaxSpeed, (AvalancheMaxSpeed - 100) / (30 * AvalancheDuration)):
      eventPlayer.setMoveSpeed(eventPlayer.AvalancheSpeed)
      wait()


def ChaseAvalancheRadius():
  @Name "Subroutine - Chase Avalanche Radius"
  
  eventPlayer.AvalancheCurrentRadius = 0.75
  #Gradually increase the size of the snowball
  chase(eventPlayer.AvalancheCurrentRadius, AvalancheRadius, duration=AvalancheDuration / 2, ChaseReeval.DESTINATION_AND_DURATION)


def ClearAvalanche():
  @Name "Subroutine - Clear Avalanche"
  
  #Root the player while the effect is clearing
  eventPlayer.setStatusEffect(null, Status.ROOTED, 1)
  chase(eventPlayer.AvalancheCurrentRadius, 0, duration=0.75, ChaseReeval.DESTINATION_AND_DURATION)
  eventPlayer.AvalancheSpeed = 500
  eventPlayer.AvalancheTimer = 0
  eventPlayer.AvalancheFinalPosition = eventPlayer.getPosition()
  eventPlayer.stopForcingThrottle()
  eventPlayer.setMoveSpeed(100)
  ExplodeAvalanche()
  #Destroy Effects
  destroyEffect(eventPlayer.AvalancheEffects)
  eventPlayer.clearStatusEffect(Status.INVINCIBLE)
  eventPlayer.clearStatusEffect(Status.ROOTED)
  eventPlayer.clearStatusEffect(Status.PHASED_OUT)
  #Reset camera to normal
  eventPlayer.stopCamera()

  eventPlayer.allowButton(Button.ABILITY_1)
  eventPlayer.allowButton(Button.ABILITY_2)
  eventPlayer.allowButton(Button.PRIMARY_FIRE)
  eventPlayer.allowButton(Button.SECONDARY_FIRE)
  eventPlayer.allowButton(Button.CROUCH)


def ExplodeAvalanche():
  @Name "Subroutine - Explode Avalanche"
  
  async(ExplodePlayersInAvalanche, AsyncBehavior.NOOP)
  #Play a bunch of effects when the ability has come to a stop
  playEffect(getAllPlayers(), DynamicEffect.EXPLOSION_SOUND, Color.WHITE, eventPlayer, 100)
  playEffect(getAllPlayers(), DynamicEffect.GOOD_EXPLOSION, Color.WHITE, eventPlayer.AvalancheFinalPosition + Vector.UP, AvalancheRadius * 2)
  playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION, Color.WHITE, eventPlayer.AvalancheFinalPosition, AvalancheRadius * 4)
  wait(0.05)
  playEffect(getAllPlayers(), DynamicEffect.GOOD_EXPLOSION, eventPlayer.getTeam(), eventPlayer.AvalancheFinalPosition + Vector.UP, AvalancheRadius * 2)
  playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION, eventPlayer.getTeam(), eventPlayer.AvalancheFinalPosition, AvalancheRadius * 4)
  wait(0.15)
  playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION, Color.WHITE, eventPlayer.AvalancheFinalPosition, AvalancheRadius * 4)
  wait(0.05)
  playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION, eventPlayer.getTeam(), eventPlayer.AvalancheFinalPosition, AvalancheRadius * 4)
  wait(0.15)
  playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION, Color.WHITE, eventPlayer.AvalancheFinalPosition, AvalancheRadius * 4)
  wait(0.05)
  playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION, eventPlayer.getTeam(), eventPlayer.AvalancheFinalPosition, AvalancheRadius * 4)
  wait(0.25)


def ExplodePlayersInAvalanche():
  @Name "Subroutine - Explode Players in Avalanche"
  
  wait(0.25)
  #Play explosion sound at position of player
  playEffect(getAllPlayers(), DynamicEffect.EXPLOSION_SOUND, Color.WHITE, eventPlayer, 100)
  #Communicate, for fun
  eventPlayer.communicate(Comms.SORRY)
  #Detach players
  while len(eventPlayer.PlayersInAvalanche) > 0:
      #Detach victom from snowball
      eventPlayer.PlayersInAvalanche[0].detach()
      #Teleport the player just in case they ended up in a wall
      eventPlayer.PlayersInAvalanche[0].teleport(nearestWalkablePosition(eventPlayer.PlayersInAvalanche[0].getPosition()))
      wait()
      #Damage affected players
      damage(eventPlayer.PlayersInAvalanche[0], eventPlayer, AvalancheDamageExplosion)
      #Throw players in avalanche away from Mei
      eventPlayer.PlayersInAvalanche[0].applyImpulse(Vector.UP, 5, Relativity.TO_WORLD, Impulse.CANCEL_CONTRARY_MOTION)
      eventPlayer.PlayersInAvalanche[0].applyImpulse(directionTowards(eventPlayer.getPosition(), eventPlayer.PlayersInAvalanche[0].getPosition()), 15, Relativity.TO_WORLD, Impulse.INCORPORATE_CONTRARY_MOTION)
      #Clear frozen status
      eventPlayer.PlayersInAvalanche[0].clearStatusEffect(Status.FROZEN)
      wait()
      #Knock players down while in the air
      eventPlayer.PlayersInAvalanche[0].setStatusEffect(eventPlayer, Status.KNOCKED_DOWN, 2)
      eventPlayer.PlayersInAvalanche = eventPlayer.PlayersInAvalanche.exclude(eventPlayer.PlayersInAvalanche[0])
  #Clear array, just in case
  eventPlayer.PlayersInAvalanche = []


rule "Avalanche is active, start facing direction":
  @Event eachPlayer
  @Condition eventPlayer.AvalancheTimer == true
  
  #Force facing direction of Mei in direction Avalanche was used
  eventPlayer.startFacing(eventPlayer.AvalancheFacingDirection, AvalancheTurnSpeed * 5, Relativity.TO_WORLD, FacingReeval.DIRECTION_AND_TURN_RATE)
  waitUntil(eventPlayer.AvalancheTimer != true, AvalancheDuration)
  eventPlayer.stopFacing()


rule "Avalanche is active and turnable, throttling":
  @Event eachPlayer
  @Condition AvalancheTurnable == true
  @Condition eventPlayer.AvalancheTimer == true
  @Condition eventPlayer.getThrottle().x != 0

  eventPlayer.AvalancheFacingDirection = angleToDirection(
    horizontalAngleOfDirection(eventPlayer.AvalancheFacingDirection) + (eventPlayer.getThrottle().x * AvalancheTurnSpeed),
    eventPlayer.getVerticalFacingAngle()
  )

  wait(0.016, Wait.ABORT_WHEN_FALSE)
  if RULE_CONDITION:
    goto RULE_START


rule "Avalanche is active, play sound":
  @Event eachPlayer
  @Condition eventPlayer.AvalancheTimer == true
  
  #Play a constant sound while snowball is rolling
  playEffect(getAllPlayers(), DynamicEffect.DEBUFF_IMPACT_SOUND, Color.WHITE, eventPlayer, 50)
  playEffect(getAllPlayers(), DynamicEffect.RING_EXPLOSION, Color.WHITE, eventPlayer.getPosition(), eventPlayer.AvalancheCurrentRadius * 2)
  wait(0.096, Wait.ABORT_WHEN_FALSE)
  if RULE_CONDITION:
      goto RULE_START


rule "Avalanche hit a wall":
  @Event eachPlayer
  @Condition eventPlayer.AvalancheTimer == true
  @Condition eventPlayer.getSpeed() < 5 * (eventPlayer.AvalancheSpeed / 100)
  
  wait(0.1, Wait.ABORT_WHEN_FALSE)
  ClearAvalanche()
  eventPlayer.setFacing(eventPlayer.AvalancheFacingDirection * -1, Relativity.TO_WORLD)


rule "Player died while using Avalanche":
  @Event playerDied
  @Condition eventPlayer.AvalancheTimer

  ClearAvalanche()


rule "Enemy is inside Avalanche":
  @Event eachPlayer
  #If any player is using avalanche
  @Condition len([player for player in getPlayers(getOppositeTeam(eventPlayer.getTeam())) if player.AvalancheTimer == true]) > 0
  #If event player is near anyone using avalanche
  @Condition any([distance(eventPlayer.getPosition(), i.getPosition()) < i.AvalancheCurrentRadius * 1.25 for i in [player for player in getPlayers(getOppositeTeam(eventPlayer.getTeam())) if player.AvalancheTimer]]) == true
  
  getClosestPlayer(eventPlayer.getPosition(), getOppositeTeam(eventPlayer.getTeam())).PlayersInAvalanche = getClosestPlayer(eventPlayer.getPosition(), getOppositeTeam(eventPlayer.getTeam())).PlayersInAvalanche.concat(eventPlayer)
  eventPlayer.attachTo(getClosestPlayer(eventPlayer.getPosition(), getOppositeTeam(eventPlayer.getTeam())), localVector(eventPlayer.getPosition(), getClosestPlayer(eventPlayer.getPosition(), getOppositeTeam(eventPlayer.getTeam())), Transform.ROTATION_AND_TRANSLATION))
  eventPlayer.setStatusEffect(null, Status.FROZEN, 5)


rule "Damage players inside of Avalanche":
  @Event eachPlayer
  @Condition eventPlayer.AvalancheTimer == true
  
  damage(eventPlayer.PlayersInAvalanche, eventPlayer, AvalancheDamagePerTick)
  wait(0.05)
  if RULE_CONDITION:
      goto RULE_START
