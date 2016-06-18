require 'sidekiq'
require 'sidekiq/api'
require_relative 'world'
require_relative 'camera'
# If your client is single-threaded, we just need a single connection in our Redis connection pool
Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'x', :size => 1 }
end

# Sidekiq server is multi-threaded so our Redis connection pool size defaults to concurrency (-c)
Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'x' }
end

include Alex
START_TIME = Time.now
FILE_PATH = 'image.sidekiq.png'
WORLD = World.new 'config/world.yml'
CAMERA = Camera.new WORLD, 'config/camera.yml'

class RayTracingJob
  include Sidekiq::Worker

  def perform(x, y)
    CAMERA.render_at(x, y)
    # @total_count += 1
    # if @total_count >= CAMERA.width * CAMERA.height
    #   CAMERA.save_image(FILE_PATH)
    #   STDERR.puts "finished, time: #{Time.now - START_TIME}"
    # end
  end
end

def start
  CAMERA.width.times do |xx|
    CAMERA.height.times do |yy|
      RayTracingJob.perform_async(xx, yy)
    end
  end
end

def clear
  Sidekiq.redis { |conn| conn.flushdb }
end