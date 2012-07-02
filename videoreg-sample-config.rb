reg {
  device      '/dev/webcam0'
  resolution  '640x480'
  fps         25
  duration    60
  filename    '#{time}-video0.avi'
  storage     '/tmp/video0'
  lockfile    '/tmp/videoreg.video0.lock'
  store_max   5
}

reg {
  device      '/dev/webcam1'
  resolution  '640x480'
  fps         25
  duration    60
  filename    '#{time}-video1.avi'
  storage     '/tmp/video1'
  lockfile    '/tmp/videoreg.video1.lock'
  store_max   3
}

reg {
  device      '/dev/video2'
  resolution  '640x480'
  fps         25
  duration    60
  filename    '#{time}-video2.avi'
  storage     '/tmp/video2'
  lockfile    '/tmp/videoreg.video2.lock'
  store_max   3
}


log_path    '/tmp/videoreg.log'
pid_path    '/tmp/videoreg.pid'
mq_queue    'com.ifree.videoreg.daemon'
mq_host     'localhost'