#!/bin/bash

# exit when any command fails
set -e

# MongoDB URI
MONGO_URI=$(cd terraform/atlas && terraform output connection_string)

# List of EC2 hosts
declare -a hostList=$(cd terraform/aws && terraform output loadtest-demo_public_dns | sed -r 's/[][,]//g' )

primary_host= 
counter=1
# Start locust
for host in ${hostList[@]}; do
host=$(echo ${host} | tr -d '"')

if [ "${counter}" -eq "1" ]
then

echo "starting primary on ${host}..."

primary_host=${host}
ssh -o StrictHostKeyChecking=accept-new -i keyfile.pem ubuntu@${host} << EOF
sudo chown -R ubuntu:ubuntu mongolocust
cd mongolocust
git pull
source venv/bin/activate
rm primary.log
export MONGO_URI="$MONGO_URI"
export AGG_WEIGHT=0
export BULK_WEIGHT=1
export DOCS_PER_BATCH=1000
nohup locust --master -f load_test.py >> primary.log 2>&1 &
EOF

echo "done!"
echo "Open your browser at http://${host}:8089"

else

echo "starting worker on ${host} with primary as ${primary_host}..."

ssh -q -o StrictHostKeyChecking=accept-new -i keyfile.pem ubuntu@${host} << EOF
sudo chown -R ubuntu:ubuntu mongolocust
cd mongolocust
git pull
source venv/bin/activate
rm worker*.log
export MONGO_URI="$MONGO_URI"
export AGG_WEIGHT=0
export BULK_WEIGHT=1
export DOCS_PER_BATCH=1000
nohup locust --worker --master-host="${primary_host}" -f load_test.py >> worker1.log 2>&1 &
nohup locust --worker --master-host="${primary_host}" -f load_test.py >> worker2.log 2>&1 &
nohup locust --worker --master-host="${primary_host}" -f load_test.py >> worker3.log 2>&1 &
nohup locust --worker --master-host="${primary_host}" -f load_test.py >> worker4.log 2>&1 &
nohup locust --worker --master-host="${primary_host}" -f load_test.py >> worker5.log 2>&1 &
nohup locust --worker --master-host="${primary_host}" -f load_test.py >> worker6.log 2>&1 &
nohup locust --worker --master-host="${primary_host}" -f load_test.py >> worker7.log 2>&1 &
nohup locust --worker --master-host="${primary_host}" -f load_test.py >> worker8.log 2>&1 &
EOF

echo "done!"

fi

counter=$((counter +1))

done
