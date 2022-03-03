#!/bin/bash

chars=abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ
for i in {1..16} ; do
    echo -n "${chars:RANDOM%${#chars}:1}"
done
echo