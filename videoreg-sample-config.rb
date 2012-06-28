reg {
  device      '/dev/video0'
  resolution  '640x480'
  fps         25
  duration    30
  filename    '#{time}-video0.avi'
  storage     '/tmp/video0'
  lockfile    '/tmp/videoreg.video0.lock'
  store_max   5
}

reg {
  device      '/dev/video1'
  resolution  '640x480'
  fps         25
  duration    30
  filename    '#{time}-video1.avi'
  storage     '/tmp/video1'
  lockfile    '/tmp/videoreg.video1.lock'
  store_max   3
}


opt 'test' => 'aaa'
opt :log_path => '/tmp/videoreg.log'
opt :pid_path => '/tmp/videoreg.pid'

