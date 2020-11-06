#! /bin/bash

set -eux

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` \
INSTANCE_ID=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id`

# あらかじめ results ディレクトリを作っておかないと vulsrepo がエラー終了する
su ec2-user -c "mkdir -p /home/ec2-user/vulsctl/docker/results"

su ec2-user -c "cd /home/ec2-user/vulsctl/docker && docker run --log-driver=awslogs --log-opt awslogs-region=${region} --log-opt awslogs-group=/ec2/vuls/vulsrepo --log-opt tag='${instance_name}-$INSTANCE_ID-{{ with split .ImageName \":\" }}{{ join . \"-\"}}{{ end }}-{{ .ID }}' --log-opt awslogs-create-group=true --restart always -dt -v /home/ec2-user/vulsctl/docker:/vuls -p 5111:5111 ishidaco/vulsrepo"