module SidekiqProcessKiller
  extend self
  attr_accessor :memory_threshold, :shutdown_wait_timeout, :shutdown_signal, :silent_mode

  self.memory_threshold = 250.0 # mb
  self.shutdown_wait_timeout = 25 # seconds
  self.shutdown_signal = "SIGKILL"
  self.silent_mode = false

  def config
    yield self
  end
end

require "get_process_mem"
require "sidekiq"
require "sidekiq_process_killer/version"
require "sidekiq_process_killer/middleware"
