#!/bin/bash
# TODO: add ability to specify multiple databags/items.
# TODO: add ability to specify all.
# TODO: add usage and examples.

BLOCK=$1
TARGET=$2
SEARCH=$3
KNIFE_PATH=/opt/chefdk/bin

if [[ ! $BLOCK =~ (aws_dev|aws_stg|aws_prd|kearney|omaha) ]] ; then
  echo "First argument must be a vaild knife block (aws_dev|aws_stg|aws_prd|kearney|omaha)."
  exit 1
fi

if [[ -z "${TARGET}" && ! "${TARGET}" =~ "/" && "${TARGET}" != "all" ]] ; then
  echo "You must enter 'databag/databag_item', or 'all' as the second argument"
  exit 1
fi

if [[ -z "${SEARCH}" || ! "${SEARCH}" =~ ":" ]] ; then
  echo "Third argument must be a valid search string. e.g '*:*'"
  exit 1
fi

arrIN=(${TARGET//// })

DATABAG=${arrIN[0]}
ITEM=${arrIN[1]}

$KNIFE_PATH/knife block use $BLOCK

if [ $($KNIFE_PATH/knife vault show $DATABAG $ITEM -p search --format json | jq -r '.search_query') -ne "${SEARCH}" ] ; then
  $KNIFE_PATH/knife vault update $DATABAG $ITEM --search "${SEARCH}"
  if [ $? -ne 0 ]
    then echo "Failed to update search query for ${TARGET}"
  fi
fi

