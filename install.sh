#!/bin/bash
CURDIR=`pwd`
cd /tmp
echo "deb http://www.rabbitmq.com/debian/ testing main" >> /etc/apt/sources.list
wget http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
apt-key add rabbitmq-signing-key-public.asc
apt-get update
apt-get install mencoder ffmpeg qc-usb-utils v4l-utils rabbitmq-server ruby1.9.1 rubygems
cd $CURDIR
bundle install
gem build videoreg.gemspec
gem install videoreg-0.1.gem