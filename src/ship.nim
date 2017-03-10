# ship.nim
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
    collider,
    draw,
    entity,
    input,
    nimgame,
    texturegraphic,
    types,
    utils],
  data


type
  Ship* = ref object of Entity
    engines: bool # engines activity flag


const
  Acceleration = (0.0, -100.0) # default acceleration for the 0 degree position
  Drag = (10.0, 10.0) # drag value
  EngineLines = [[(-4.0, 8.0), (-3.0, 8.0)], [(3.0, 8.0), (4.0, 8.0)]] # \
    # line coordinates for the engines


proc reset*(ship: Ship) =
  # reset ship's position to the center of the screen
  ship.pos.x = game.size.w / 2 / game.scale.x
  ship.pos.y = game.size.h / 2 / game.scale.y
  ship.vel = (0.0, 0.0)
  ship.acc = (0.0, 0.0)
  ship.dead = false


proc init*(ship: Ship) =
  ship.initEntity()
  ship.tags.add("ship")
  ship.graphic = gfxData["ship"]
  ship.physics = new Physics
  ship.drg = Drag
  ship.centrify()
  ship.collider = ship.newPolyCollider(
    (0.0, 0.0), [(0.0, -7.0), (7.0, 7.0), (-7.0, 7.0)])
  ship.collider.tags.add("rock") # check collisions "ship - rock" only
  ship.reset()


proc newShip*(): Ship =
  new result
  result.init()


method render*(ship: Ship) =
  ship.renderEntity()
  # draw engines
  if ship.engines:
    for ln in EngineLines:
      var line = [
        rotate(ln[0], ship.pos, ship.rot),
        rotate(ln[1], ship.pos, ship.rot)]
      discard thickLine(line[0], line[1], game.scale.x, 0xFF0000FF'u32)


method update*(ship: Ship, elapsed: float) =
  ship.updateEntity(elapsed)

  # rotation
  ship.rot = direction(ship.pos, (mouse.abs / game.scale))

  # acceleration
  if MouseButton.right.down:
    ship.acc = rotate(Acceleration, ship.rot)
    ship.engines = true
  else:
    ship.engines = false
    ship.acc = (0.0, 0.0)


method update*(physics: Physics, ship: Ship, elapsed: float) =
  physics.updatePhysics(ship, elapsed)

  let
    gameDim: Coord = game.size.Coord / game.scale
    shipDim: Coord = TextureGraphic(ship.graphic).dim / 2

  # X limits
  if ship.pos.x < -shipDim.x:
    ship.pos.x = gameDim.x + shipDim.x
  elif ship.pos.x > gameDim.x + shipDim.x:
    ship.pos.x = -shipDim.x

  # Y limits
  if ship.pos.y < -shipDim.y:
    ship.pos.y = gameDim.y + shipDim.y
  elif ship.pos.y > gameDim.y + shipDim.y:
    ship.pos.y = -shipDim.y


method onCollide*(ship: Ship, target: Entity) =
  if "rock" in target.tags:
    ship.dead = true
    justDied = true
    respawnCooldown = RespawnCooldown
    discard sfxData["explosion"].play()

