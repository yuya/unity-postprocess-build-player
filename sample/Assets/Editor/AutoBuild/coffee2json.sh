#!/bin/sh

if ! type coffee > /dev/null 2>&1; then echo "Please install coffee-script"; exit; fi
if [[ ! "${1}" =~ \.coffee$ ]];    then echo "File extension error";         exit; fi

echo \{
  cat $1 | \
  coffee --print --bare --compile --stdio | \
  sed -e '1,2d; $d' | \
  sed "s/\([^ '\"].*[^ '\"]\): /\"\1\": /"
echo \}
