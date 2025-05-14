#!/bin/bash
set -e
exec > >(tee -a /var/log/user-data.log) 2>&1

apt install -y rclone

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
            "log_group_name": "/bench/rclonesync-maxfilecount",
            "log_stream_name": "{instance_id}/user-data",
            "timestamp_format": "%Y-%m-%dT%H:%M:%S"
          },
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "/bench/rclonesync-maxfilecount",
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

mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf <<EOF
[aws]
type = s3
provider = AWS
env_auth = true
access_key_id =
secret_access_key =
region = eu-west-1
EOF

# Benchmark scripts
mkdir -p /opt/bench/rclonesyncMaxFileCount
aws s3 cp s3://diploma-scripts/benchmarkMaxFileCount.sh /opt/bench/benchmarkMaxFileCount.sh
aws s3 cp s3://diploma-scripts/rclonesyncMaxFileCount.sh /opt/bench/rclonesyncMaxFileCount/rclonesyncMaxFileCount.sh

chmod +x /opt/bench/benchmarkMaxFileCount.sh
chmod +x /opt/bench/rclonesyncMaxFileCount/rclonesyncMaxFileCount.sh
cd /opt/bench
sudo -E ./benchmarkMaxFileCount.sh rclonesyncMaxFileCount

sudo shutdown -h now
