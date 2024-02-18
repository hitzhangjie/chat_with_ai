#!/bin/bash 

echo $1

sed -i 's/GitHub\ Copilot/GitHub\ Copilot:/' $1
sed -i 's/hitzhangjie/hitzhangjie:/' $1
sed -i 's/:/:\r-----------------------------------------------------------------------------------/' $1


