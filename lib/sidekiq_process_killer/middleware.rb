module SidekiqProcessKiller
  class Middleware
    LOG_PREFIX = self.name
    METRIC_PREFIX = "sidekiq_process_killer".freeze

    attr_accessor :pid, :worker, :jid, :queue, :memory

    def call(worker, job, queue)
      yield

      @pid        = ::Process.pid
      @worker     = worker.class
      @queue      = queue
      @memory     = process_memory.mb
      @jid        = job['jid']

      memory_threshold = SidekiqProcessKiller.memory_threshold
      return if memory_threshold > memory

      log_warn("Breached RSS threshold at #{memory_threshold}. Sending TERM Signal.")

      send_signal("SIGTERM", pid)
      sleep(SidekiqProcessKiller.shutdown_wait_timeout)

      shutdown_signal = SidekiqProcessKiller.shutdown_signal

      begin
        metric_params = {
          worker_name: worker.class,
          current_memory_usage: memory,
          queue_name: queue,
        }

        ::Process.getpgid(pid)
        log_warn("Forcefully killing process with #{shutdown_signal}.")

        increment_statsd(metric_params.merge(metric_name: "process.killed.forcefully"))

        send_signal(shutdown_signal, pid)
      rescue Errno::ESRCH
        log_warn("Process killed successfully.")

        increment_statsd(metric_params.merge(metric_name: "process.killed.successfully"))
      end
    end

    private def process_memory
      @memory ||= GetProcessMem.new
    end

    private def humanized_attributes
      instance_variables.map do |var|
        key = var.to_s.gsub("@", "").capitalize
        value = instance_variable_get(var)
        "#{key}: #{value}"
      end.join(", ")
    end

    private def silent_mode_msg
      SidekiqProcessKiller.silent_mode ? " [SILENT]" : ""
    end

    private def log_warn(msg)
      Sidekiq.logger.warn("[#{LOG_PREFIX}]#{silent_mode_msg} #{msg} #{humanized_attributes}")
    end

    private def log_info(msg)
      Sidekiq.logger.info("[#{LOG_PREFIX}]#{silent_mode_msg} #{msg} #{humanized_attributes}")
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
