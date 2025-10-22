#!/bin/bash

echo "NHS Notify Feature starting post start command script"
/usr/local/share/nhsnotify/scripts/makeconfig.sh
/usr/local/share/nhsnotify/scripts/welcome.sh
/usr/local/share/nhsnotify/scripts/github-monitor.sh --rate-limit
/usr/local/share/nhsnotify/scripts/github-monitor.sh -d

echo "NHS Notify Feature finished post start command script"