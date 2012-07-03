1. Составляется конфиг-файл config.rb:

```ruby
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
```

1. После установки скриптов на машине запуск регистрации происходит при помощи команды videoreg:

```
	$ videoreg -h
	Usage: videoreg [options]
	    -c, --config CONFIG              Use the specified config
	    -d, --device DEVICE              Run only the specified device
	    -H, --halt DEVICE                Halt (SIGKILL) recording process
	    -P, --pause DEVICE               Pause (SIGSTOP) recording process
	    -R, --resume DEVICE              Resume (SIGCONT) recording process
	    -r, --recover DEVICE             Recover the recording process
	    -p, --pid PID                    Set the PID file for the capture process
	    -l, --log LOGFILE                Set the logfile for daemon
	    -e, --ensure                     Check the state of the daemon
	    -C, --clear                      Clear the state (remove lock-files)
	    -k, --kill                       Kills the capture processes
	    -v, --version                    Show the version
	    -h, --help                       Show this help message
	    -U, --udev                       Generate udev rules for current config
	    -I, --info                       Show info about plugged devices
```
1. Информация о текущем статусе демона:
```
	$  videoreg -c config.rb -e
	Running command 'ensure' for device(s): 'all'...
	DAEMON:		     [RUNNING]
	Uptime:		     4sec
	/dev/webcam0: 	 [RUNNING]
	/dev/webcam1: 	 [RUNNING]
	/dev/webcam2: 	 [NO DEVICE]
```
1. Запуск демона:
```
	$ videoreg -s config.rb
	Daemon has started successfully
```
1. Остановка:
```
	$ videoreg -s config.rb --k
	Stopped PID: 3870 at /tmp/videoreg.pid
```
1. Остановить конкретный регистратор (для определённого устройства):
```
	$ videoreg -c config.rb -H /dev/webcam0
	Running command 'halt' for device(s): '/dev/webcam0'...
	I, [2012-07-03T14:00:35.802428 #8115]  INFO -- : Publish message to RabbitMQ 'HALT' with arg '/dev/webcam0' to 'com.ifree.videoreg.daemon'...
	I, [2012-07-03T14:00:36.347704 #8115]  INFO -- : Disconnecting from RabbitMQ...

	$ videoreg -c config.rb -e
	Running command 'ensure' for device(s): 'all'...
	DAEMON:		     [RUNNING]
	Uptime:		     1min 18sec
	/dev/webcam0: 	 [NOT RUNNING]
	/dev/webcam1: 	 [RUNNING]
	/dev/webcam2: 	 [NO DEVICE]
```
1. Запустить конкретный регистратор:
```
	$ videoreg -c config.rb -r /dev/webcam0
	Running command 'recover' for device(s): '/dev/webcam0'...
	I, [2012-07-03T14:02:12.375352 #8193]  INFO -- : Publish message to RabbitMQ 'RECOVER' with arg '/dev/webcam0' to 'com.ifree.videoreg.daemon'...
	I, [2012-07-03T14:02:12.920787 #8193]  INFO -- : Disconnecting from RabbitMQ...

	$ videoreg -c config.rb -e
	Running command 'ensure' for device(s): 'all'...
	DAEMON:		     [RUNNING]
	Uptime:		     2min 34sec
	/dev/webcam0: 	 [RUNNING]
	/dev/webcam1: 	 [RUNNING]
	/dev/webcam2: 	 [NO DEVICE]
```
1. Приостановить регистратор:
```
	$ videoreg -c config.rb -P /dev/webcam0
	Running command 'pause' for device(s): '/dev/webcam0'...
	I, [2012-07-03T14:03:28.840693 #8254]  INFO -- : Publish message to RabbitMQ 'PAUSE' with arg '/dev/webcam0' to 'com.ifree.videoreg.daemon'...
	I, [2012-07-03T14:03:29.386111 #8254]  INFO -- : Disconnecting from RabbitMQ...

	$ videoreg -c config.rb -e
	Running command 'ensure' for device(s): 'all'...
	DAEMON:		     [RUNNING]
	Uptime:		     3min 50sec
	/dev/webcam0: 	 [PAUSED]
	/dev/webcam1: 	 [RUNNING]
	/dev/webcam2: 	 [NO DEVICE]
```
1. Возобновить регистратор:
```
	$ videoreg -c config.rb -R /dev/webcam0
	Running command 'resume' for device(s): '/dev/webcam0'...
	I, [2012-07-03T14:04:34.870130 #8308]  INFO -- : Publish message to RabbitMQ 'RESUME' with arg '/dev/webcam0' to 'com.ifree.videoreg.daemon'...
	I, [2012-07-03T14:04:35.415852 #8308]  INFO -- : Disconnecting from RabbitMQ...

	$ videoreg -c config.rb -e
	Running command 'ensure' for device(s): 'all'...
	DAEMON:		     [RUNNING]
	Uptime:		     4min 58sec
	/dev/webcam0: 	 [RUNNING]
	/dev/webcam1: 	 [RUNNING]
	/dev/webcam2: 	 [NO DEVICE]
```
1. Получить информацию о подключённых камерах:
```
	$ videoreg -I
	usb1[1-1] --> /dev/webcam0
	usb2[2-1] --> /dev/webcam1
```
1. Сгенерировать файл с правилами udev:
```
	$ videoreg -U
	Writing the rules to /etc/udev/rules.d/50-udev-videoreg.rules file:
	            BUS=="usb" ACTION=="add" DEVPATH=="/devices/pci0000:00/0000:00:1a.0/usb1/1-1/*/video4linux/video*" SYMLINK+="webcam0" GROUP="video"
	            BUS=="usb" ACTION=="add" DEVPATH=="/devices/pci0000:00/0000:00:1d.0/usb2/2-1/*/video4linux/video*" SYMLINK+="webcam1" GROUP="video"
	File has been written successfully! Now restart udev (/etc/init.d/udev restart) and replug the webcams!
```

# Changelog

## 03.07.2012
### Current status
* Реализация правил udev (добавление симлинков на девайсы по определённым правилам)

## 29.06.2012
### Current status
* Проверка наличия всех девайсов (камер)
* По команде прервать запись с определенной камеры и начать заново (это нужно чтобы вытащить кадр из текущего кусочка записи)
* "Ленивая" инициализация заданной камеры: пауза/запуск процесса записи

## 28.06.2012
### Current status
* Запуск видеозаписи
    * Параметры для всех камер хранятся в одном конфиге (разрешение, фпс, длительность каждого файла)
    * Запись по кускам (по 10минут в один файл например)
    * Слежение

### TODO
* Состояние системы (свободное место на винте, время работы с момента последней перезагрузки и тп) – тоже в конфиге как-то хранить
* Слежение за свободным местом на диске (например записи с камер 1 и 2 должны хранится 12 часов, но все вместе не более 15Гб)
* Алерты об ошибках в Приложение1
* Запуск Приложения3 – при появлении файлов с определенной камеры надо запускать нашу программку (Приложение2), потом файлик удалять (или не удалять – параметр в конфиге)