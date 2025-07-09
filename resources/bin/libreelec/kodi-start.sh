#!/bin/bash

stop()
{
  echo "Starting kodi"
  systemctl start kodi
}

trap stop EXIT


