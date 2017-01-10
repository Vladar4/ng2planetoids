#!/bin/sh
cd src
nim c --out:../ng2planetoids -d:release --opt:speed ng2planetoids.nim
rm -rf nimcache

