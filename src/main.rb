require_relative 'camera'
require_relative 'world'
#require 'facets'
include Alex

# require 'ruby-prof'
# RubyProf.start
Random.srand(1)
world = World.new 'config/world.yml'
camera = Camera.new world, 'config/camera.yml'
camera.render_sync 'image.png'

# result = RubyProf.stop
#
# printer = RubyProf::FlatPrinter.new(result)
# printer.print(STDOUT)


