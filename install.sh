#!/bin/bash
CURDIR=`pwd`
cd /tmp
if grep -q "deb http://www.rabbitmq.com/debian/ testing main" /etc/apt/sources.list
then
    echo "It seems you are installing env second time..."
else
    echo "deb http://www.rabbitmq.com/debian/ testing main" >> /etc/apt/sources.list
    wget http://www.rabbitmq.com/rabbitmq-signing-key-public.asc
    apt-key add rabbitmq-signing-key-public.asc
    apt-get update
fi
apt-get install mencoder ffmpeg qc-usb-utils v4l-utils rabbitmq-server ruby1.9.1 rubygems
cd $CURDIR
gem install bundler
bundle install
gem build videoreg.gemspec
gem install videoreg-0.1.gem