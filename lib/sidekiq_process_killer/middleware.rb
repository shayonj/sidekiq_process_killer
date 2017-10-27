module SidekiqProcessKiller
  class Middleware
    LOG_PREFIX = self.name
    METRIC_PREFIX = "sidekiq_process_killer".freeze

    def call(worker, job, queue)
      pid = ::Process.pid
      log_info("Listening on process #{pid} and awaiting completion")

      yield

      memory_threshold = SidekiqProcessKiller.memory_threshold
      return if memory_threshold > memory.mb

      log_warn("Process #{pid} is currently breaching RSS threshold of #{memory_threshold} with #{memory.mb}")
      log_warn("Sending TERM to #{pid}. Worker: #{worker.class}, JobId: #{job['jid']}, queue: #{queue}")

      send_signal("SIGTERM", pid)
      sleep(SidekiqProcessKiller.shutdown_wait_timeout)

      shutdown_signal = SidekiqProcessKiller.shutdown_signal

      begin
        ::Process.getpgid(pid)
        log_warn("Forcefully killing #{pid}, with #{shutdown_signal}")
        send_signal(shutdown_signal, pid)

        increment_statsd({
          metric_name: "process.killed.forcefully",
          worker_name: worker.class,
          current_memory_usage: memory.mb
        })
      rescue Errno::ESRCH
        log_warn("Process #{pid} killed successfully")

        increment_statsd({
          metric_name: "process.killed.successfully",
          worker_name: worker.class,
          current_memory_usage: memory.mb
        })
      end
    end

    private def memory
      @memory ||= GetProcessMem.new
    end

    private def silent_mode_msg
      SidekiqProcessKiller.silent_mode ? " [SILENT]" : ""
    end

    private def log_warn(msg)
      Sidekiq.logger.warn("[#{LOG_PREFIX}]#{silent_mode_msg} #{msg}")
    end

    private def log_info(msg)
      Sidekiq.logger.info("[#{LOG_PREFIX}]#{silent_mode_msg} #{msg}")
    end

    private def send_signal(name, pid)
      return if SidekiqProcessKiller.silent_mode

      ::Process.kill(name, pid)
    end

    private def increment_statsd(params)
      statsd_klass = SidekiqProcessKiller.statsd_klass
      return unless statsd_klass.respond_to?(:increment)

      params[:metric_name] = "#{METRIC_PREFIX}.#{params[:metric_name]}"
      statsd_klass.increment(params)
    end
  end
end
