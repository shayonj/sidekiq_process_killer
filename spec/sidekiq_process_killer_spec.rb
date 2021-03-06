require "spec_helper"

RSpec.describe SidekiqProcessKiller do
  it "has a version number" do
    expect(SidekiqProcessKiller::VERSION).not_to be nil
  end

  it "has the default config" do
    expect(SidekiqProcessKiller.memory_threshold).to eq(250.0)
    expect(SidekiqProcessKiller.silent_mode).to eq(false)
    expect(SidekiqProcessKiller.statsd_klass).to eq(nil)
  end

  it "successfully updates the config" do
    object = Object.new
    SidekiqProcessKiller.config do |con|
      con.memory_threshold = 1024.0
      con.silent_mode = true
      con.statsd_klass = object
    end

    expect(SidekiqProcessKiller.memory_threshold).to eq(1024.0)
    expect(SidekiqProcessKiller.silent_mode).to eq(true)
    expect(SidekiqProcessKiller.statsd_klass).to eq(object)
  end

  context "memory_threshold=" do
    it "plays nice when passed in nil" do
      SidekiqProcessKiller.config do |con|
        con.memory_threshold = nil
      end

      expect(SidekiqProcessKiller.memory_threshold).to eq(0.0)
    end

    it "plays nice when passed in as string" do
      SidekiqProcessKiller.config do |con|
        con.memory_threshold = "2048.8656"
      end

      expect(SidekiqProcessKiller.memory_threshold).to eq(2048.8656)
    end

    it "plays nice when passed in unexpected value like a hash" do
      SidekiqProcessKiller.config do |con|
        con.memory_threshold = {}
      end

      expect(SidekiqProcessKiller.memory_threshold).to eq(0.0)
    end
  end
end
