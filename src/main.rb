require_relative 'camera'
require_relative 'world'
include Alex

if ARGV.size != 4
  puts 'parameter error'
  exit
end

Random.srand(1)
mode = ARGV[0]
out_file = ARGV[1]
world_file = ARGV[2]
camera_file = ARGV[3]
world = World.new world_file
camera = Camera.new world, camera_file
if mode == 's'
  camera.render_sync out_file
else
  threads = mode.to_i
  camera.render_fork out_file, threads
end


