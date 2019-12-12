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
   echo "Installing fio and toilet"
   sudo apt-get install -yqq fio toilet >/tmp/fio-install.log 2>&1 || sudo apt-get install -yqq fio toilet >/tmp/fio-install.log 2>&1 || sudo cat /tmp/fio-install.log
 fi

 function go_fio_1test() {
   local cmd=$1
   local disk=$2
   local caption="$3"
   pushd "$disk" >/dev/null
   toilet -f term -F border "$caption ($(pwd))"
   echo "Benchmark '$(pwd)' folder using '$cmd' test during $DURATION seconds and heating $RAMP secs, size is $SIZE"
   if [[ $cmd == "rand"* ]]; then
      fio --name=RUN_$cmd --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --filename=fiotest.tmp --bs=4k --iodepth=64 --size=$SIZE --runtime=$DURATION --ramp_time=$RAMP --readwrite=$cmd
   else
      fio --name=RUN_$cmd --ioengine=libaio --direct=1 --gtod_reduce=1 --filename=fiotest.tmp --bs=1024k --size=$SIZE --runtime=$DURATION --ramp_time=$RAMP --readwrite=$cmd
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
   rm -f $disk/fiotest.tmp
 }
 
 go_fio_4tests "$DISK" "$CAPTION"
