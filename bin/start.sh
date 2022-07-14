#!/bin/bash

dir=$(pwd)
self=$(basename "$0")
here="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
data=$here/../data


cleanup() {
 sudo losetup -d /dev/loop0
 rm $data/disk.img
}

create_disk() {
 mkdir -p $data
 fallocate -l 64M $data/disk.img
 yes | sudo mkfs.ext4 $data/disk.img
 # sudo mkfs.xfs -f $data/disk.img
 sudo losetup /dev/loop0 $data/disk.img
}

exec_docker() {
 docker run -it --privileged \
    -v /dev/loop0:/dev/loop0 \
    -v $here:/code \
    ubuntu /code/start.sh test_1
}

test_1() {
  mkdir /data
  mount /dev/loop0 /data
  df -h /data
  echo "#Writing 32MB -> should work."
  dd if=/dev/zero of=/data/testfile bs=1M count=32 oflag=direct
  df -h /data
  echo "#Writing 64MB -> should fail (Expected output: No space left on device)" 
  dd if=/dev/zero of=/data/testfile bs=1M count=64 oflag=direct
  df -h /data
}

opt=$1
case $opt
in
    cleanup) 
      cleanup 
      ;;
    create_disk)
      cleanup
      create_disk
      ;;
    docker)
      echo $self
      (exec $here/$self "create_disk")
      exec_docker
      ;;
    test_1)
      echo "Testing within Docker(Writing to /data)."
      test_1
      ;;
esac      

