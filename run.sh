#!/bin/bash

sudo chvt 9

sudo openvt -f -c 9 -- /home/pi/src/OctoShUI/OctoShUI.sh --daemon $@
