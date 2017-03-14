#!/bin/sh

S_PLATFORM=`uname`
if [ "${S_PLATFORM}" != 'Linux' ]; then
    exit 0
fi

if [ -z "$1" ]; then
    echo "Please specify a docker-machine name."
    echo ""
    echo "Usage: $0 default "
    echo ""
    echo "Available machine(s) include: "
    for m in $(docker-machine ls -q); do
        echo "   - $m"
    done
    exit 12
fi

BINDING=r
set -xe
if [ $(docker-machine status "$1" | grep -i 'running' > /dev/null 2>&1 ; echo $? ) -ne 0 ]; then
    echo "Starting docker machine:..."
    docker-machine start "$1"
    eval $(docker-machine env "$1")
    BINDING=
fi

echo "Mounting host home folder..."
COMMANDS=$(cat <<-EOF
    ls -1 /hosthome | while read d
    do sudo mkdir -p "/home/\${d}" && \
    sudo mount -o ${BINDING}bind,uid=$(id -u),gid=$(id -g) \
        "/hosthome/\${d}" "/home/\${d}"
    done
EOF
)
docker-machine ssh "$1" "${COMMANDS}"

echo "Done"
