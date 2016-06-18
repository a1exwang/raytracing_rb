# This is a simple Resque job.
require_relative 'camera'
require_relative 'world'
include Alex
require 'resque'

Random.srand(1)
class RayTracingJob
  @queue = :default
  def self.perform(task = 'init'.to_sym, file_path = 'image.resque.png', x = 0, y = 0)
    if task == :init
      @start_time = Time.now
      @file_path = file_path
      @world = World.new 'config/world.yml'
      @camera = Camera.new @world, 'config/camera.yml'
      @camera.width.times do |xx|
        @camera.height.times do |yy|
          Resque.enqueue(RayTracingJob, file_path, xx, yy)
        end
      end
    else
      @camera.render_at(x, y)
      @total_count += 1
      if @total_count >= @camera.width * @camera.height
        @camera.save_image(@file_path)
        STDERR.puts "finished, time: #{Time.now - @start_time}"
      end
    end
  end
end
#
# job = RayTracingJob.new('image.png')
# job.start