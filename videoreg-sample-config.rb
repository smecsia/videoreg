reg {
  device      '/dev/webcam0'
  resolution  '640x480'
  fps         25
  duration    60
  filename    '#{time}-webcam0.avi'
  storage     '/tmp/webcam0'
  lockfile    '/tmp/videoreg.webcam0.lock'
  store_max   5
}

reg {
  device      '/dev/webcam1'
  resolution  '640x480'
  fps         25
  duration    60
  filename    '#{time}-webcam1.avi'
  storage     '/tmp/webcam1'
  lockfile    '/tmp/videoreg.webcam1.lock'
  store_max   3
}

reg {
  device      '/dev/webcam2'
  resolution  '640x480'
  fps         25
  duration    60
  filename    '#{time}-webcam2.avi'
  storage     '/tmp/webcam2'
  lockfile    '/tmp/videoreg.webcam2.lock'
  store_max   3
}


log_path    '/tmp/videoreg.log'
pid_path    '/tmp/videoreg.pid'
mq_queue    'com.ifree.videoreg.daemon'
mq_host     'localhost'