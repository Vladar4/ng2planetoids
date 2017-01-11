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
    entity,
    font,
    input,
    nimgame,
    scene,
    settings,
    textgraphic,
    types],
  data, rock, ship, shot


type
  ScnMain* = ref object of Scene
    ship: Ship
    cooldown: float # shooting cooldown (in seconds)


const
  Cooldown = 0.5  # shooting cooldown value (in seconds)


var
  mainScene*: ScnMain


proc init*(scn: ScnMain) =
  Scene(scn).init()

  # infoText
  let
    infoText = newEntity()
    infoTextG = newTextGraphic(fntData["default8x16"])
  infoTextG.lines = ["Nimgame 2 Planetoids v1.0"]
  infoText.graphic = infoTextG
  infoText.scale = 0.5
  infoText.pos = (8 / game.scale.x, (game.size.h.float - 20) / game.scale.y)
  infoText.layer = 10

  # ship
  scn.ship = newShip()

  # add to scene
  scn.add(scn.ship)
  for i in 0..3:
    scn.add(newRock(0))
  scn.add(infoText)


proc newScnMain*(): ScnMain =
  new result
  result.init()


method event*(scn: ScnMain, event: Event) =
  if event.kind == KeyDown:
    case event.key.keysym.scancode:
      of ScancodeEscape:
        gameRunning = false
      of ScancodeF10: # toggle outlines
        colliderOutline = not colliderOutline
      of ScancodeF11: # toggle info
        showInfo = not showInfo
      else: discard


method show*(scn: ScnMain) =
  scn.cooldown = Cooldown


method update*(scn: ScnMain, elapsed: float) =
  scn.updateScene(elapsed)
  # Shooting cooldown
  if scn.cooldown != 0:
    scn.cooldown -= elapsed
    if scn.cooldown < 0:
      scn.cooldown = 0
  # Shooting
  if Button.left.pressed and scn.cooldown == 0:
    let shot = newShot(scn.ship.pos, scn.ship.rot)
    scn.add(shot)
    scn.cooldown = Cooldown
  # New rocks
  for entity in scn.entities:
    if "rock" in entity.tags:
      let rock = Rock(entity)
      while rock.newRocks.len > 0:
        scn.add(rock.newRocks.pop())

