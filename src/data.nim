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
  nimgame2 / [
    assets,
    audio,
    bitmapfont,
    texturegraphic,
    types]


var
  fntData*: Assets[BitmapFont]
  gfxData*: Assets[TextureGraphic]
  sfxData*: Assets[Sound]
  score*, lives*: int
  justDied*: bool
  explosions*: seq[Coord]


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

