
require 'rake/extensiontask'
require 'rspec/core/rake_task'
require 'sidekiq/api'

Rake::ExtensionTask.new('fast_4d_matrix')
RSpec::Core::RakeTask.new(:spec => :compile)

require 'resque/tasks'
require_relative 'src/resque'

namespace :resque do
  desc "Clear pending tasks"
  task :clear do
    queues = Resque.queues
    queues.each do |queue_name|
      puts "Clearing #{queue_name}..."
      Resque.redis.del "queue:#{queue_name}"
    end

    puts "Clearing delayed..." # in case of scheduler - doesn't break if no scheduler module is installed
    Resque.redis.keys("delayed:*").each do |key|
      Resque.redis.del "#{key}"
    end
    Resque.redis.del "delayed_queue_schedule"

    puts "Clearing stats..."
    Resque.redis.set "stat:failed", 0
    Resque.redis.set "stat:processed", 0
  end
  desc 'start ray tracing'
  task :image do
    Resque.enqueue(RayTracingJob)
  end
end

namespace :sidekiq do
  desc 'clear tasks'
  task :clear do
    Sidekiq.redis { |conn| conn.flushdb }
  end
end
