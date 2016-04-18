#!/bin/sh

echo "Compiling..."
jflex $1.flex
byaccj -vJ $1.y
javac *.java
