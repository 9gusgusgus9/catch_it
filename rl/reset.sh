#!/bin/sh

sudo rm Qtable-catch_it.csv
sudo lua create_Q-table.lua Qtable-catch_it.csv 160 8
sudo chmod 777 Qtable-catch_it.csv
