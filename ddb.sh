#!/bin/bash
set -e

cat >&2 <<-'EOWARN'
	****************************************************
                   The following ports / services
                     * 5555 / dalmatiner DB
	****************************************************
EOWARN

CONF=/data/dalmatinerdb/etc/dalmatinerdb.conf

export HOST=$(ping -c1 $HOSTNAME | awk '/^PING/ {print $3}' | sed 's/[():]//g')||'127.0.0.1'

export CLUSTER_NAME=${CLUSTER_NAME:-ddb}

export COORDINATOR_NODE=${COORDINATOR_NODE:-$HOSTNAME}

export COORDINATOR_NODE_HOST=$(ping -c1 $COORDINATOR_NODE | awk '/^PING/ {print $3}' | sed 's/[():]//g')||'127.0.0.1'


export RING_SIZE=${RING_SIZE:-64}


## Update config
sed -i \
    -e "s/^nodename = .*/nodename = ${CLUSTER_NAME}@${HOST}/" \
    -e "s/^handoff.ip = .*/handoff.ip = ${HOST}/" \
    $CONF

echo "ring_size = ${RING_SIZE}" >> $CONF

admin=/dalmatinerdb/bin/ddb-admin
ddb=/dalmatinerdb/bin/ddb

$ddb start
$admin wait-for-service metric
$admin wait-for-service event

if [ ! "${COORDINATOR_NODE_HOST}" = "${HOST}" ]
then
    $admin cluster join ${CLUSTER_NAME}@${COORDINATOR_NODE_HOST}
    sleep $(( ( RANDOM % 10 )  + 5 ))
    $admin cluster plan
    $admin cluster commit
else
    IFS=';' read -r -a buckets <<< "${BUCKETS}"
    for bucket in "${buckets[@]}"
    do
        $admin buckets create ${bucket}
    done
fi

$admin buckets list

tail -n 1024 -f /data/dalmatinerdb/log/console.log
