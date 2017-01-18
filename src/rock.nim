# rock.nim
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
  math, random,
  sdl2/sdl,
  nimgame2 / [
    assets,
    audio,
    collider,
    draw,
    entity,
    nimgame,
    procgraphic,
    texturegraphic,
    types,
    utils
  ],
  data


type
  RockGraphic* = ref object of ProcGraphic
    poly*: seq[Coord]

  Rock* = ref object of Entity
    size*: range[0..2]
    dim*: Coord
    newRocks*: seq[Rock]

const
  RockRotVel = 30.0
  RockFillColor: Color = 0x909090FF'u32
  # ===================================
  # FOR ROCK SIZE :   0     1      2
  # ===================================
  RockPolyRadius =  [24.0, 12.0,   6.0]
  RockPolyRandom =  [12.0,  4.0,   1.0]
  RockPolyDotCount =[12,    6,     4]
  RockVel =         [50.0, 85.0, 125.0]
  RockScore* =       [10,   40,   200]


var
  gameSize: Coord = (0.0, 0.0)


proc drawRock*(graphic: ProcGraphic,
               pos: Coord,
               angle: Angle,
               scale: Scale,
               center: Coord,
               flip: Flip,
               region: Rect) =
  let rock = RockGraphic(graphic)
  if rock.poly == nil:
    return
  # modify points
  var coords: seq[Coord] = @[]
  for i in rock.poly:
    coords.add(rotate(i, pos - center, angle) * scale)
  # draw
  discard polygon(coords, RockFillColor, DrawMode.filled)


proc newRockGraphic(): RockGraphic =
  new result
  result.procedure = drawRock


proc init*(rock: Rock, size: range[0..2] = 0, pos: Coord = (0.0, 0.0)) =
  rock.initEntity()

  # get game window size once
  if gameSize == (0.0, 0.0):
    gameSize = game.size.Coord / game.scale

  rock.tags.add("rock")
  rock.size = size
  rock.dim = (RockPolyRadius[rock.size], RockPolyRadius[rock.size])
  rock.newRocks = @[]
  rock.graphic = newRockGraphic()

  # generate random polygon points
  RockGraphic(rock.graphic).poly = @[]
  for i in 0..(RockPolyDotCount[size] - 1):
    let
      radius = RockPolyRadius[size]
      a = 2 * Pi * i.float / RockPolyDotCount[size].float
    var
      x = radius * cos(a) +
        random(RockPolyRandom[size]) - RockPolyRandom[size] / 2
      y = radius * sin(a) +
        random(RockPolyRandom[size]) - RockPolyRandom[size] / 2
    RockGraphic(rock.graphic).poly.add((x, y))

  rock.collider = newPolyCollider(rock, (0, 0), RockGraphic(rock.graphic).poly)
  rock.collider.tags.add("nil") # do not check collisions "rock - target"
  rock.physics = new Physics

  # set position
  if pos == (0.0, 0.0):
    let dim: Coord = (game.size.w div game.scale.x.int,
                      game.size.h div game.scale.y.int)
    case random(4):
    of 0: # left side
      rock.pos.x = 50
      rock.pos.y = random(dim.y - 100) + 50
    of 1: # right side
      rock.pos.x = dim.x - 50
      rock.pos.y = random(dim.y - 100) + 50
    of 2: # top side
      rock.pos.x = random(dim.x - 100) + 50
      rock.pos.y = 50
    of 3: # bottom side
      rock.pos.x = random(dim.x - 100) + 50
      rock.pos.y = dim.y - 50
    else: discard
  else:
    rock.pos = pos

  # set speed
  let spd = RockVel[size] / 2
  rock.vel = (random(spd) + spd, random(spd) + spd)
  rock.rotVel = random([-1.0, 1.0]) * random(RockRotVel / 2) + RockRotVel / 2


proc newRock*(size: range[0..2] = 0, pos: Coord = (0.0, 0.0)): Rock =
  new result
  result.init(size, pos)


method update*(rock: Rock, elapsed: float) =
  rock.updateEntity(elapsed)

  # X limits
  if rock.pos.x < -rock.dim.x:
    rock.pos.x = gameSize.x + rock.dim.x
  elif rock.pos.x > gameSize.x + rock.dim.x:
    rock.pos.x = -rock.dim.x

  # Y limits
  if rock.pos.y < -rock.dim.y:
    rock.pos.y = gameSize.y + rock.dim.y
  elif rock.pos.y > gameSize.y + rock.dim.y:
    rock.pos.y = -rock.dim.y


method update*(physics: Physics, rock: Rock, elapsed: float) =
  physics.updatePhysics(rock, elapsed)


proc shatter*(rock: Rock, angle: Angle) =
  rock.dead = true
  score += RockScore[rock.size]
  explosions.add(rock.pos)
  discard sfxData["explosion"].play()
  case rock.size:
  of 0:
    let rockA = newRock(1, rock.pos)
    rocka.vel = rotate((0.0, RockVel[1]), angle - random(45.0) - 45.0)
    rock.newRocks.add(rockA)
    let rockB = newRock(1, rock.pos)
    rockB.vel = rotate((0.0, RockVel[1]), angle + random(45.0) + 45.0)
    rock.newRocks.add(rockB)
  of 1:
    let rockA = newRock(2, rock.pos)
    rockA.vel = rotate((0.0, RockVel[2]), angle - random(45.0) - 45.0)
    rock.newRocks.add(rockA)
    let rockB = newRock(2, rock.pos)
    rockB.vel = rotate((0.0, RockVel[2]), angle + random(45.0) + 45.0)
    rock.newRocks.add(rockB)
  of 2:
    discard


method onCollide*(rock: Rock, target: Entity) =
  if "shot" in target.tags:
    rock.shatter(target.rot)

