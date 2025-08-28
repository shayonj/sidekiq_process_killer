# SidekiqProcessKiller

[![CI](https://github.com/shayonj/sidekiq_process_killer/workflows/CI/badge.svg)](https://github.com/shayonj/sidekiq_process_killer/actions)

When you have memory leaks or "bloats" in your ruby application, identifying and fixing them can at times be a nightmare. Instead, an _"acceptable"_ mitigation is to re-spin the workers. Its a common technique that can be found in [Puma Worker Killer](https://github.com/schneems/puma_worker_killer) or [Unicorn Worker Killer](https://github.com/kzk/unicorn-worker-killer). Though, its neater and good practice to find and fix your leaks.

SidekiqProcessKiller plugs into Sidekiq's middleware and kills a process (by sending `SIGTERM`) if its processing beyond the supplied [RSS](https://en.wikipedia.org/wiki/Resident_set_size) threshold. Since this plugs into the middleware, the check is performed after each job.

## Installation

```ruby
  gem "sidekiq_process_killer"
```

## Usage

### Configuration


```ruby
memory_threshold: 250.0 # mb
silent_mode: false
statsd_klass: nil
```



| Config name           	| Description                                                                                                                                                                                                                                                                                                                                                                                                	|
|-------------------------	|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| `silent_mode`           	| When set to `true`, no signal will be sent to running process. This is helpful if you are planning to launch this, but want to first do a dry run.
| `memory_threshold`      	| When current RSS is above this threshold, the respective Sidekiq worker will be instructed for termination (via `TERM` signal, which sidekiq gracefully exits).                                                                                                                                                                                                                                                                                                                                                                                                              	|
| `statsd_klass`          	| This is a class object which responds to an `increment`. If present, the `increment` function will be called with a single argument of type `Hash` which contains, `metric_name`, `worker_name` and `current_memory_usage`. This class is called when attempting to terminate a process or if the process had to be forcefully be terminated.	|


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
