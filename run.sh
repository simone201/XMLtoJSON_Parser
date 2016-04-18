#!/bin/sh 

clear
./clean.sh
./compile.sh xml_parser
java Parser $1
