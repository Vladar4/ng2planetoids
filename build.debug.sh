#!/bin/sh
cd src
nim c --out:../ng2planetoids -d:nimDebugDlOpen --multimethods:on ng2planetoids.nim
cd ..

