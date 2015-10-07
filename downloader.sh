#!/bin/bash

function usage {
  echo -e "Usage:\n\t`basename $0` <url> [chunk size (default: 128mb)] [filename (default: autodetect)]"
  exit 1
}

#Cleanup on kill
function clean {
  kill 0
  rm /tmp/$FILENAME.* 2> /dev/null
  echo "Download failed!"
  exit 1
}

function getUriFilename() {
    header="$(curl -sI "$1" | tr -d '\r')"

    filename="$(echo "$header" | grep -o -E 'filename=.*$')"
    if [[ -n "$filename" ]]; then
        echo "${filename#filename=}"
        return
    fi

    filename="$(echo "$header" | grep -o -E 'Location:.*$')"
    if [[ -n "$filename" ]]; then
        basename "${filename#Location\:}"
        return
    fi

    filename="$(basename $1)"

    echo "${filename%%\?*}"
    return
}

#Check parameters
if [ ! "$1" ] ; then
  echo "Where's the URL?"
  usage
fi

if [ "$2" ] ; then
    if [[ $2 =~ ^[0-9]+$ ]] ; then
        echo "Setting chunk size: {$2}..."
    else
        echo "Chunk size should be a number. Its best to use maximum download limit as chunk size."
        usage
    fi
fi

SPLITSIZE=${2:-${downloader_chunk_size:-128}}
SPLITSIZE=$(($SPLITSIZE * 1024 * 1024))

URL=$1

if [ "$3" ] ; then
  FILENAME=$3
else
  FILENAME="$(getUriFilename $URL)"
fi

SIZE="`curl -qIL $URL 2> /dev/null|awk '/Length/ {print $2}'|grep -o '[0-9]*'`"
SIZE=${SIZE:-1}

SPLITNUM=$((${SIZE:-0}/$SPLITSIZE))

[ $SPLITNUM -ne 0 ] || SPLITNUM=1

START=0
CHUNK=$((${SIZE:-0}/$SPLITNUM))
END=$CHUNK

OUT_DIR=${downloader_output_dir:-$HOME/Downloads}

echo "Downloading to: $OUT_DIR {$FILENAME}..."

#Trap ctrl-c
trap 'clean' SIGINT SIGTERM

#Test splitness
OUT=`curl -m 2 --range 0-0 $URL 2> /dev/null|while read -n 1 C;do
  OUT="${OUT}½"
  echo $OUT
  [ ${#OUT} -gt 1 ] && break
done`

#Check out
case ${#OUT} in
0)  clean;; #Curl error
1)  ;; #Got a byte
*)  echo Server does not spit...;SPLITNUM=1;; #Got more than asked for
esac

#Invoke curls
for PART in `eval echo {1..$SPLITNUM}`;do
  curl --ftp-pasv -o "/tmp/$FILENAME.$PART" --range $START-$END $URL 2> /dev/null &
  START=$(($START+$CHUNK+1))
  END=$(($START+$CHUNK))
done

TIME=$((`date +%s`-1))
function calc {
 GOTSIZE=$((`eval ls -l "/tmp/$FILENAME".{1..$SPLITNUM} 2> /dev/null|awk 'BEGIN{SUM=0}{SUM=SUM+$5}END{print SUM}'`))
 TIMEDIFF=$(( `date +%s` - $TIME ))
 RATE=$(( ($GOTSIZE / $TIMEDIFF)/1024 ))
 PCT=$(( ($GOTSIZE*100) / $SIZE ))
}

#Wait for all parts to complete while spewing progress
while jobs | grep -q Running ; do
 calc
 echo -n "Downloading $FILENAME in $SPLITNUM parts: $(($GOTSIZE/1048576)) / $(($SIZE/1048576)) mb @ $(($RATE)) kb/s ($PCT%).    "
 tput ech ${#SIZE}
 tput cub 1000
 sleep 1
done

calc
echo "Downloading $FILENAME in $SPLITNUM parts: $(($GOTSIZE/1048576)) / $(($SIZE/1048576)) mb @ $(($RATE)) kb/s ($PCT%).    "

#Check if file name exists
FILENAME2=$FILENAME
if [ -f "$OUT_DIR/$FILENAME2" ] ; then
  read -p "$FILENAME2 already exists in $OUT_DIR. Do you want to overwrite? [n/y] " opt
  case $opt in
    [Yy]* ) break;;
    *)
      i=2
      while [[ -f "$OUT_DIR/$FILENAME2" ]]; do
        FILENAME2="${FILENAME%.*}($i).${FILENAME#*.}"
        i=$(($i+1))
      done
  esac
fi

#Join all the parts
eval cat "/tmp/$FILENAME".{1..$SPLITNUM} > "/$OUT_DIR/$FILENAME2"
echo "Download completed! Check file $FILENAME2 in $OUT_DIR."
rm /tmp/$FILENAME.* 2> /dev/null
