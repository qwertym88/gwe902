#!/bin/sh
# gen_e902.sh {path to E902_RTL_FACTORY} {E902_asic_rtl.fl}

CODE_BASE_PATH=${1}
FL_NAME=${2:-E902_asic_rtl.fl}
OUT_NAME=opene902.v

echo > $OUT_NAME

for fpath in $(grep -e '\.[vh]$' ${CODE_BASE_PATH}/gen_rtl/filelists/${FL_NAME})
do
    eval echo Appending ${fpath} to ${OUT_NAME}...
    eval cat $fpath >> $OUT_NAME
done