#!/usr/bin/env bash

 CAPTION=$1
 DISK=$2
 SIZE=$3
 DURATION=$4
 RAMP=$5

 CAPTION=${CAPTION:-Current Folder}
 DISK=${DISK:-$(pwd)}
 SIZE=${SIZE:-1G}
 DURATION=${DURATION:-30}
 RAMP=${RAMP:-5}

 if [[ "$(command -v fio 2>/dev/null)" == "" || "$(command -v toilet 2>/dev/null)" == "" ]]; then
   sudo apt-get install -yqq fio toilet
 fi

 function go_fio_1test() {
   local cmd=$1
   local disk=$2
   local caption="$3"
   pushd "$disk" >/dev/null
   toilet -f term -F border "$caption ($(pwd))"
   echo "Benchmark '$(pwd)' folder using '$cmd' test during $DURATION seconds heating $RAMP secs, size is $SIZE"
   if [[ $cmd == "rand"* ]]; then
      fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=4k --iodepth=64 --size=$SIZE --readwrite=$cmd --runtime=$DURATION --ramp_time=$RAMP
   else
      fio --ioengine=libaio --direct=1 --gtod_reduce=1 --name=fiotest --filename=fiotest --bs=1024k --size=$SIZE --readwrite=$cmd --runtime=$DURATION --ramp_time=$RAMP
   fi
   popd >/dev/null
   echo ""
 }
 
 function go_fio_4tests() {
   local disk=$1
   local caption=$2
   go_fio_1test read      $disk "${caption}: Sequential read"
   go_fio_1test write     $disk "${caption}: Sequential write"
   go_fio_1test randread  $disk "${caption}: Random read"
   go_fio_1test randwrite $disk "${caption}: Random write"
   rm -f $disk/fiotest
 }
 
 go_fio_4tests "$DISK" "$CAPTION"
