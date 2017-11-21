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
      increment_statsd({
        metric_name: "process.term.signal.sent",
        worker_name: worker.class,
        current_memory_usage: memory
      })
      send_signal("SIGTERM", pid)
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
