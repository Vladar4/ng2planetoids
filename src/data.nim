# data.nim
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
  os,
  nimgame2 / [
    assets,
    audio,
    bitmapfont,
    scene,
    texturegraphic,
    types]


const
  NameLimit = 32
  RespawnCooldown* = 1.0
  HiscoresDir = getConfigDir().joinPath("ng2planetoids")
  HiscoresPath = HiscoresDir.joinPath("hiscores.dat")


type
  Name* = array[NameLimit, char]
  Hiscore* = object
    name*: Name
    score*: uint64


var
  titleScene*, mainScene*: Scene
  fntData*: Assets[BitmapFont]
  gfxData*: Assets[TextureGraphic]
  sfxData*: Assets[Sound]
  hiscores*: array[10, Hiscore]
  score*, lives*: int
  justDied*: bool
  explosions*: seq[Coord]
  respawnCooldown*: float


proc loadData*() =
  fntData = newAssets[BitmapFont]("data/fnt",
    proc(file: string): BitmapFont = newBitmapFont(file, (8, 16)))
  gfxData = newAssets[TextureGraphic]("data/gfx",
    proc(file: string): TextureGraphic = newTextureGraphic(file))
  sfxData = newAssets[Sound]("data/sfx",
    proc(file: string): Sound = newSound(file))


proc freeData*() =
  for fnt in fntData.values:
    fnt.free()
  for gfx in gfxData.values:
    gfx.free()
  for sfx in sfxData.values:
    sfx.free()


proc toName*(str: string): Name =
  let lim = if str.high < NameLimit: str.high else: NameLimit - 1
  for i in 0..(NameLimit - 1):
    result[i] = ' '
  for i in 0..lim:
    result[i] = str[i]


proc toString*(name: Name): string =
  result = ""
  for c in name:
    result.add(c)


proc initHiscores*() =
  var
    f: File
    line: Hiscore
  let
    size = sizeof(line)

  if f.open(HiscoresPath, fmRead, size):
    # Read existing hiscores
    var i = 0
    while f.readBuffer(addr(line), size) == size:
      hiscores[i] = line
      inc i

  else:
    discard existsOrCreateDir(HiscoresDir)
    # Fill a new hiscores file
    if not f.open(HiscoresPath, fmWrite, size):
      echo "ERROR: can't create hiscores.dat"
      return
    for i in 0..9:
      line.name = toName("none")
      line.score = 0
      discard f.writeBuffer(addr(line), size)

  f.close()


proc writeHiscores*() =
  var
    f: File
    line: Hiscore
  let
    size = sizeof(line)

  discard f.open(HiscoresPath, fmWrite, size)
  for i in 0..9:
    line = hiscores[i]
    discard f.writeBuffer(addr(line), size)

  f.close()


proc shiftScores(idx: int) =
  for i in countdown(9, idx + 1):
    hiscores[i] = hiscores[i-1]


proc checkForHiscore*(newScore: uint): int =
  result = -1
  for i in 0..9:
    if newScore > hiscores[i].score:
      shiftScores(i)
      hiscores[i].score = newScore
      result = i
      break

