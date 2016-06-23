#!/bin/bash
# Usage:
# knife_vault_add_admin.sh <knife block> <username>
# 
# Example:
# knife_vault_add_admin.sh aws_dev acline

BLOCK=$1
USER=$2
KNIFE_PATH=/opt/chefdk/bin

if [[ ! $BLOCK =~ (aws_dev|aws_stg|aws_prd|kearney|omaha) ]] ; then
  echo "First argument must be a vaild knife block (aws_dev|aws_stg|aws_prd|kearney|omaha)."
  exit 1
fi

if [ -z "${USER}" ] ; then
  echo "You must supply a username to add as an admin as the second argument"
  exit 1
fi

$KNIFE_PATH/knife block use $BLOCK

for i in $(knife data bag list); do
  for j in $(knife data bag show $i|grep _keys$|sed s/_keys$//); do 
    knife vault update -A "$USER" $i $j
    if [ ! $? -eq 0 ]
      then printf "%s\n" "--FAILED--" "data bag: ${i}" "item: ${j}"
    fi
  done
done

for i in $(knife data bag list); do 
  for j in $(knife data bag show $i|grep _keys$|sed s/_keys$//); do 
    knife vault refresh $i $j
    if [ ! $? -eq 0 ]
      then printf "%s\n" "--FAILED--" "data bag: ${i}" "item: ${j}"
    fi
  done
done
