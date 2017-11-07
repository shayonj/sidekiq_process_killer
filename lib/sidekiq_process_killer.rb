module SidekiqProcessKiller
  extend self

  attr_accessor :shutdown_wait_timeout, :shutdown_signal, :silent_mode, :statsd_klass

  self.shutdown_wait_timeout = 25 # seconds
  self.shutdown_signal = "SIGKILL"
  self.silent_mode = false
  self.statsd_klass = nil

  def config
    yield self
  end

  def memory_threshold
    @memory_threshold || 250.0
  end

  def memory_threshold=(value)
    unless value.respond_to?(:to_f)
      return @memory_threshold = 0.0
    end

    @memory_threshold = value.to_f
  end

end

require "get_process_mem"
require "sidekiq"
require "sidekiq_process_killer/version"
require "sidekiq_process_killer/middleware"
