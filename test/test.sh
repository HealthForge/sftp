#!/bin/sh -e

. ./config.sh

trap 'echo "Cleaning up... "; rm -f msg-actual.json; docker exec sftp rm -r /home/test /target/test' EXIT

echo -n "Starting AMQP listener... "
amqp-consume -u amqp://localhost:5672 -q sftp -x -c 1 cat > msg-actual.json &
echo " ok"

echo -n "Uploading test file... "
env -i scp -q -F /dev/null -P $SSH_PORT -i ssh/test_id_rsa test-upload.txt test@localhost:inbox/
echo " ok"

echo -n "Waiting for file to appear in target directory... "  # tried to do this with inotifywait but it was more hassle than it was worth
while ! [ -f target/test/test-upload.txt ]; do
    sleep 1
done
diff -q test-upload.txt target/test/test-upload.txt
echo " ok"

echo -n "Checking message content... "
jq -Sc . msg-actual.json | diff rabbitmq/msg-expected.json -
echo " ok"
