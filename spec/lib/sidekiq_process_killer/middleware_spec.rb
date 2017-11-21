require "spec_helper"

RSpec.describe SidekiqProcessKiller::Middleware do
  let(:input) { [double(class: "Foo"), {"jid" => "1234"}, "default"] }
  let(:pid) { 1 }
  let(:statsd_klass) { double(increment: nil) }

  after(:each) do
    SidekiqProcessKiller.config do |con|
      con.memory_threshold = 250.0
      con.silent_mode = false
      con.statsd_klass = nil
    end
  end

  it "has a log prefix" do
    expect(SidekiqProcessKiller::Middleware::LOG_PREFIX).to eq("SidekiqProcessKiller::Middleware")
  end

  it "has the attributes set correctly" do
    allow_any_instance_of(GetProcessMem).to receive(:mb).and_return(10.22)
    allow(::Process).to receive(:pid).and_return(pid)

    instance = SidekiqProcessKiller::Middleware.new
    instance.call(*input) do
      # do something
    end

    expect(instance.jid).to eq("1234")
    expect(instance.worker).to eq("Foo")
    expect(instance.queue).to eq("default")
    expect(instance.memory).to eq(10.22)
    expect(instance.pid).to eq(pid)
  end

  it "successfully turns instance variables into humanized attributes" do
    allow_any_instance_of(GetProcessMem).to receive(:mb).and_return(10.22)
    allow(::Process).to receive(:pid).and_return(pid)

    instance = SidekiqProcessKiller::Middleware.new
    instance.call(*input) do
      # do something
    end

    expect(instance.send(:humanized_attributes)).to eq("Pid: 1, Worker: Foo, Queue: default, Memory: 10.22, Jid: 1234")
  end

  it "returns early if there current RSS is below threshold" do
    SidekiqProcessKiller.config do |con|
      con.memory_threshold = 10.0
    end
    expect(::Process).to_not receive(:kill)
    allow_any_instance_of(GetProcessMem).to receive(:mb).and_return(1)

    SidekiqProcessKiller::Middleware.new.call(*input) do
      # do something
    end
  end

  it "sends SIGTERM when RSS is above threshold and forcefully kills worker when beyond shutdown timeout" do
    SidekiqProcessKiller.config do |con|
      con.statsd_klass = statsd_klass
    end

    allow_any_instance_of(GetProcessMem).to receive(:mb).and_return(4000.0)
    allow(::Process).to receive(:pid).and_return(pid)

    expect(::Process).to receive(:kill).with("SIGTERM", 1)

    expect(statsd_klass).to receive(:increment).with({
      metric_name: "sidekiq_process_killer.process.term.signal.sent",
      worker_name: String,
      current_memory_usage: 4000.0
    })

    SidekiqProcessKiller::Middleware.new.call(*input) do
      # do something
    end
  end

  it "does not need any signal when silent mode is on" do
    SidekiqProcessKiller.config do |con|
      con.silent_mode = true
    end

    expect(::Process).to_not receive(:kill)
    expect(::Process).to_not receive(:getpgid)
    expect(::Process).to_not receive(:kill)

    SidekiqProcessKiller::Middleware.new.call(*input) do
      # do something
    end
  end

  it "sends statsd metrics by incrementing, using the supplied statsd class object" do
    SidekiqProcessKiller.config do |con|
      con.statsd_klass = statsd_klass
    end

    allow_any_instance_of(GetProcessMem).to receive(:mb).and_return(4000.0)
    allow(::Process).to receive(:pid).and_return(pid)

    expect(::Process).to receive(:kill).with("SIGTERM", 1)

    expect(statsd_klass).to receive(:increment).with({
      metric_name: "sidekiq_process_killer.process.term.signal.sent",
      worker_name: String,
      current_memory_usage: 4000.0
    })

    SidekiqProcessKiller::Middleware.new.call("some_worker", {}, "") do
      # do something
    end
  end
end
