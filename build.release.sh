#!/bin/sh
cd src
nim c --out:../ng2planetoids -d:release --opt:speed --multimethods:on ng2planetoids.nim
cd ..

