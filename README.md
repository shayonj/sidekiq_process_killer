# SidekiqProcessKiller

[![Build Status](https://travis-ci.org/shayonj/sidekiq_process_killer.svg?branch=master)](https://travis-ci.org/shayonj/sidekiq_process_killer)

When you have memory leaks or "bloats" in your ruby application, identifying and fixing them can at times be a nightmare. Instead, an _"acceptable"_ mitigation is to re-spin the workers. Its a common technique that can be found in [Puma Worker Killer](https://github.com/schneems/puma_worker_killer) or [Unicorn Worker Killer](https://github.com/kzk/unicorn-worker-killer). Though, its neater and good practice to find and fix your leaks.

SidekiqProcessKiller plugs into Sidekiq's middleware and kills a process if its processing beyond the supplied [RSS](https://en.wikipedia.org/wiki/Resident_set_size) threshold. Since this plugs into the middleware, the check is performed after each job.

## Installation

**While in testing period, this is not published to a public server, yet. Until then:**

Add the following to your Gemfile

```ruby
  gem "sidekiq_process_killer", git: "git://github.com/shayonj/sidekiq_process_killer.git"
```

## Usage

### Configuration

The default configurations are:

```ruby
memory_threshold: 250.0 # mb
shutdown_wait_timeout: 25 # seconds
shutdown_signal: "SIGKILL"
silent_mode: false
statsd_klass: nil
```

- `silent_mode`: When set to `true`, it will mean that no signals for terminate or otherwise will be sent. This is helpful if you are planning to launch this, but want to first do a dry run.
- `memory_threshold`: This is the threshold, which, when, breached, the respective Sidekiq worker will be instructed for termination (via `TERM` signal, which sidekiq gracefully exits).
- `shutdown_signal`: Signal for force shutdown/kill/quit.
- `shutdown_wait_timeout`: If, for some reason, the process takes more than the timeout defined in `shutdown_wait_timeout`, to die, the process will be forced terminated using the signal set in `shutdown_signal`.
- `statsd_klass`: This is your custom statsd class object which responds to an `increment` function. If present, then it will send custom metrics about the worker process that is being terminated and its respective RSS.
  - The `increment` is called with a single argument of type `Hash` which contains, `metric_name`, `worker_name` and `current_memory_usage`. The implementation of this may not be very flexible, its expected that your custom class reads the passed in information and appropriately send to your statsd agent. PRs/patches welcome to extend this functionality :).

### Updating default configuration:

```ruby
class CustomMetric
  ...

  def increment(params)
    StatsD.count(
      params[:metric_name],
      tags: {
        worker_name: params[:worker_name]
      }
    )
  end

  ...
end

SidekiqProcessKiller.config do |con|
  con.memory_threshold = 1024.0
  con.shutdown_wait_timeout = 60
  con.shutdown_signal = "SIGUSR2"
  con.silent_mode = false
  con.statsd_klass = CustomMetric.new # your custom statsd class object
end
```

### Turn on SidekiqProcessKiller

Just plugin the Middleware

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add SidekiqProcessKiller::Middleware
  end
end
```

The class tries to log as much as possible, as best as possible.
