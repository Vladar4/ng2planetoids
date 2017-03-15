# scn_main.nim
# Copyright (c) 2017 Vladar
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Vladar vladar4@gmail.com

import
  nimgame2 / [
    assets,
    audio,
    entity,
    font,
    input,
    nimgame,
    scene,
    settings,
    textfield,
    textgraphic,
    types,
    utils],
  data, rock, ship, shot


type
  ScnMain* = ref object of Scene
    crash, status, inputLabel, inputText, pause: Entity
    ship: Ship
    cooldown: float # shooting cooldown (in seconds)


const
  LayerEffects = 5
  LayerGUI = 10
  Cooldown = 0.5  # shooting cooldown value (in seconds)
  RockWaveScore = RockScore[0] + 2 * RockScore[1] + 4 * RockScore[2]


var
  hiscoreIdx: int
  defaultFont: Font


proc init*(scn: ScnMain) =
  Scene(scn).init()

  defaultFont = fntData["default8x16"]

  # info
  let
    info = newEntity()
    infoText = newTextGraphic(defaultFont)
  infoText.lines = ["Nimgame 2 Planetoids v1.01"]
  info.graphic = infoText
  info.scale = 0.5
  info.pos = (4.0, game.size.h.float - 10.0)
  info.layer = LayerGUI

  # status
  let
    statusText = newTextGraphic(defaultFont)
  scn.status = newEntity()
  scn.status.graphic = statusText
  scn.status.pos = (4.0, 4.0)
  scn.status.layer = LayerGUI

  # input
  let
    iLbl = newTextGraphic(defaultFont)
    iTxt = newTextField(defaultFont)
  scn.inputLabel = newEntity()
  scn.inputText = newEntity()
  scn.inputLabel.graphic = iLbl
  scn.inputText.graphic = iTxt
  iLbl.lines = ["ENTER YOUR NAME"]
  iTxt.limit = 32
  scn.inputLabel.centrify()
  scn.inputText.centrify()
  scn.inputLabel.pos = (game.size.w / 2,
                        game.size.h / 2)
  scn.inputText.pos =  (game.size.w / 2,
                        game.size.h / 2 + defaultFont.charH.float)
  scn.inputLabel.layer = LayerGUI
  scn.inputText.layer = LayerGUI

  # pause
  let
    pauseText = newTextGraphic(defaultFont)
  scn.pause = newEntity()
  scn.pause.graphic = pauseText
  pauseText.lines = ["PAUSE"]
  scn.pause.centrify()
  scn.pause.pos = (game.size.w / 2,
                   game.size.h / 2)
  scn.pause.layer = LayerGUI
  scn.pause.visible = false

  # crash
  scn.crash = newEntity()
  scn.crash.layer = LayerEffects
  scn.crash.graphic = gfxData["crash"]
  scn.crash.initSprite((24, 34))
  scn.crash.centrify()
  discard scn.crash.addAnimation("crash", (0..7).toSeq, 0.05)


  # ship
  scn.ship = newShip()

  # add to scene
  scn.add(info)
  scn.add(scn.pause)
  scn.add(scn.status)
  scn.add(scn.ship)


proc newScnMain*(): ScnMain =
  new result
  result.init()


method event*(scn: ScnMain, event: Event) =
  if event.kind == KeyDown:
    # Entering name
    if scn.inputText in scn:
      let tf = TextField(scn.inputText.graphic)

      case event.key.keysym.scancode:
      of ScancodeBackspace:
        tf.bs()
        scn.inputText.centrify()
      of ScancodeDelete:
        tf.del()
        scn.inputText.centrify()
      of ScancodeLeft:
        tf.left()
      of ScancodeRight:
        tf.right()
      of ScancodeHome:
        tf.toFirst()
      of ScancodeEnd:
        tf.toLast()
      of ScancodeReturn:
        tf.deactivate()
      else: discard

    else:

      case event.key.keysym.scancode:
        of ScancodeEscape:
          game.scene = titleScene
        of ScancodeP: # pause/unpause
          if scn.inputLabel notin scn:
            gamePaused = not gamePaused
            scn.pause.visible = gamePaused
        of ScancodeF10: # toggle outlines
          colliderOutline = not colliderOutline
        of ScancodeF11: # toggle info
          showInfo = not showInfo
        else: discard

  elif event.kind == TextInput:
    # Entering name
    if scn.inputText in scn:
      TextField(scn.inputText.graphic).add($event.text.text)
      scn.inputText.centrify()


method show*(scn: ScnMain) =
  scn.cooldown = Cooldown
  score = 0
  lives = 4
  justDied = false
  explosions = @[]
  hiscoreIdx = -1
  scn.del("rock")
  for i in 0..3:
    scn.add(newRock(0))


method update*(scn: ScnMain, elapsed: float) =
  scn.updateScene(elapsed)

  # Entering name
  if scn.inputText in scn:
    let tf = TextField(scn.inputText.graphic)
    if not tf.isActive:
      hiscores[hiscoreIdx].name = tf.text.toName
      hiscores[hiscoreIdx].score = score.uint
      writeHiscores()
      discard scn.del(scn.inputLabel)
      discard scn.del(scn.inputText)
      game.scene = titleScene
      scn.ship.reset()
      scn.add(scn.ship)
    return

  # Shooting cooldown
  if scn.cooldown != 0:
    scn.cooldown -= elapsed
    if scn.cooldown < 0:
      scn.cooldown = 0

  # New rocks
  for entity in scn.entities:
    if "rock" in entity.tags:
      let rock = Rock(entity)
      while rock.newRocks.len > 0:
        scn.add(rock.newRocks.pop())

  while explosions.len > 0:
    # add explosion
    let
      explosion = explosions.pop()
      expl = newEntity()
    expl.layer = LayerEffects
    expl.graphic = gfxData["explosion"]
    expl.initSprite((56, 48))
    expl.centrify()
    discard expl.addAnimation("expl", (0..25).toSeq, 0.05)
    expl.pos = explosion
    expl.play("expl", 1, kill = true)
    scn.add(expl)

  # No more rocks
  if "rock" notin scn:
    for i in 0..(2 + score div (2 * RockWaveScore)):
      scn.add(newRock(0))

  if justDied:
    justDied = false
    # Crash
    scn.crash.dead = false
    scn.add(scn.crash)
    scn.crash.pos = scn.ship.pos
    scn.crash.play("crash", 1, kill = true)

  # Respawn cooldown
  if respawnCooldown > 0:
    respawnCooldown -= elapsed
    if respawnCooldown < 0:
      respawnCooldown = 0

  # Ship is dead
  if scn.ship.dead:
    if lives > 0:
      # Respawn
      if MouseButton.left.down and respawnCooldown <= 0:
        dec lives
        scn.ship.dead = false
        scn.ship.reset()
        scn.cooldown = Cooldown
        scn.add(scn.ship)
    # No more lives left
    else:
      hiscoreIdx = checkForHiscore(uint(score))
      if hiscoreIdx >= 0:
        scn.add(scn.inputLabel)
        scn.add(scn.inputText)
        TextField(scn.inputText.graphic).activate()
        return

      game.scene = titleScene

  # Ship is alive
  else:
    # Shooting
    if MouseButton.left.down and scn.cooldown == 0:
      let shot = newShot(scn.ship.pos, scn.ship.rot)
      scn.add(shot)
      scn.cooldown = Cooldown
      discard sfxData["shot"].play()


  # Update status
  TextGraphic(scn.status.graphic).lines = [
    "" & $score,
    "" & $lives & " LIVES"]

