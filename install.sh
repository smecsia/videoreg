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
apt-get install -y mencoder ffmpeg qc-usb-utils v4l-utils rabbitmq-server ruby1.9.1 rubygems ruby1.9.1-dev
ln -sf /usr/bin/ruby1.9.1 /usr/bin/ruby
ln -sf /usr/bin/rake1.9.1 /usr/bin/rake
ln -sf /usr/bin/gem1.9.1 /usr/bin/gem
ln -sf /usr/bin/irb1.9.1 /usr/bin/irb
export GEM_BIN=/var/lib/gems/1.9.1/bin
export PATH=$PATH:$GEM_BIN
cd $CURDIR
gem install bundler --no-rdoc --no-ri
if [ -f $GEM_BIN/bundle ];
then
    export BUNDLER=$GEM_BIN/bundle
else
    export BUNDLER=/var/lib/gems/1.8/bin/bundle
fi

if [ -f $BUNDLER ];
then
    $BUNDLER install
    $BUNDLER exec gem install dist/videoreg-0.1.gem

    echo "Information about plugged devices:"
    videoreg -I
    videoreg -U
else
    echo "Bundler executable not found ($BUNDLER)! Installation FAILED!"
fi
