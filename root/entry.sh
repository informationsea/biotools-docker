#!/bin/sh
unset LD_LIBRARY_PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [ $# -eq 0 ];then
    exec /bin/bash
else
    "$@"
fi