pid_path = '/tmp/videoreg.pid'
log_path = '/tmp/videoreg.log'

God.watch do |w|
  w.name            = "videoreg"
  w.interval        = 30.seconds
  w.start           = "videoreg -l #{log_path} -P #{pid_path} -c videoreg-sample-config.rb"
  w.stop            = "videoreg -l #{log_path} -P #{pid_path} -c videoreg-sample-config.rb -k"
  w.start_grace     = 15.seconds
  w.restart_grace   = 15.seconds
  w.pid_file        = pid_path
  w.keepalive

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end
end