require "spec_helper"

RSpec.describe SidekiqProcessKiller do
  it "has a version number" do
    expect(SidekiqProcessKiller::VERSION).not_to be nil
  end

  it "has the default config" do
    expect(SidekiqProcessKiller.memory_threshold).to eq(250.0)
    expect(SidekiqProcessKiller.shutdown_wait_timeout).to eq(25)
    expect(SidekiqProcessKiller.shutdown_signal).to eq("SIGKILL")
  end

  it "successfully updates the config" do
    SidekiqProcessKiller.config do |con|
      con.memory_threshold = 1024.0
      con.shutdown_wait_timeout = 60
      con.shutdown_signal = "SIGUSR1"
    end

    expect(SidekiqProcessKiller.memory_threshold).to eq(1024.0)
    expect(SidekiqProcessKiller.shutdown_wait_timeout).to eq(60)
    expect(SidekiqProcessKiller.shutdown_signal).to eq("SIGUSR1")
  end
end
