#!/bin/bash
set -e

exec > >(tee -a /var/log/user-data.log) 2>&1
# aws-cli already installed

# CloudWatch Agent
CW_AGENT_DEB="/tmp/cw-agent.deb"
curl -sS https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -o "${CW_AGENT_DEB}"
dpkg -i "${CW_AGENT_DEB}"

cat >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<CFG
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/bench/awss3sync-large",
            "log_stream_name": "{instance_id}/user-data",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S"
          },
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "/bench/awss3sync-large",
            "log_stream_name": "{instance_id}/cloud-init",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S"
          }
        ]
      }
    }
  }
}
CFG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

# Benchmark scripts
mkdir -p /opt/bench/awss3syncLarge
aws s3 cp s3://diploma-scripts/benchmarkLarge.sh /opt/bench/benchmarkLarge.sh
aws s3 cp s3://diploma-scripts/awss3syncLarge.sh /opt/bench/awss3syncLarge/awss3syncLarge.sh

chmod +x /opt/bench/benchmarkLarge.sh
chmod +x /opt/bench/awss3syncLarge/awss3syncLarge.sh
cd /opt/bench
sudo -E ./benchmarkLarge.sh awss3syncLarge

sudo shutdown -h now
