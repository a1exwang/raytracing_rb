require_relative 'camera'
require_relative 'world'
require 'facets'
include Alex

# require 'ruby-prof'
# RubyProf.start

world = World.new 'config/world.yml'
camera = Camera.new world, 'config/camera.yml'
camera.render 'image.png'

# result = RubyProf.stop
#
# printer = RubyProf::FlatPrinter.new(result)
# printer.print(STDOUT)


