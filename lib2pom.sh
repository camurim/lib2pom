#!/usr/bin/env bash

DIRECTORY=$1
APIURL="https://search.maven.org/solrsearch/select?q=!artifact!&rows=5&wt=json"

urlencode() {
  local LC_ALL=C
  local string="$*"
  local length="${#string}"
  local char

  for (( i = 0; i < length; i++ )); do
    char="${string:i:1}"
    if [[ "$char" == [a-zA-Z0-9.~_-] ]]; then
      printf "$char"
    else
      printf '%%%02X' "'$char"
    fi
  done
  printf '\n' # opcional
}

file2dependency() {
    filename=$(basename -- "$1")
    filename="${filename%.*}"

    search=$(urlencode ${filename%-*})
    search=$(echo $APIURL | sed "s/\!artifact\!/$search/g")
    result=$(curl -sSL $search | jq '.response.docs[0]')

    artifact=$(echo $result | jq '.a' | sed 's/\"//g')
    group=$(echo $result | jq '.g' | sed 's/\"//g')
    version=$(echo $result | jq '.latestVersion' | sed 's/\"//g')

    if [[ $artifact == "null" ]]; then
        echo "<!-- FIXME: $filename -->"
    else
        echo "<!-- OK: $filename -->"
    fi

    echo -e "<dependency>\n\t<groupId>$group</groupId>\n\t<artifactId>$artifact</artifact>\n\t<version>$version</version>\n</dependency>"
}

for f in ${DIRECTORY}/*.jar; do
    file2dependency $f
done
