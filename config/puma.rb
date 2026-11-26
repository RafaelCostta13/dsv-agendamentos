threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", 3))
threads threads_count, threads_count

workers_count = Integer(ENV.fetch("PUMA_WORKERS", 0))
workers workers_count if workers_count.positive?
worker_timeout Integer(ENV.fetch("PUMA_WORKER_TIMEOUT", 60)) if workers_count.positive?

bind "tcp://0.0.0.0:#{Integer(ENV.fetch("RAILS_PORT", 3000))}"
pidfile "tmp/pids/server.pid"
plugin :tmp_restart
