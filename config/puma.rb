threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", 3))
threads threads_count, threads_count

bind "tcp://0.0.0.0:3000"
pidfile "tmp/pids/server.pid"
plugin :tmp_restart
