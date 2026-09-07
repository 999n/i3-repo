#!/bin/bash
ACTION=$1
STEP=10
if [ "$ACTION" = "increase" ]; then
    i3-msg "gaps right current plus $STEP"
elif [ "$ACTION" = "decrease" ]; then
    i3-msg "gaps right current minus $STEP"
fi
