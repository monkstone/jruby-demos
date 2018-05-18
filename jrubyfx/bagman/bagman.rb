#!/usr/bin/env jruby
# Ported but substantially changed from (example5):
# https://github.com/tutsplus/Introduction-to-JavaFX-for-Game-Development.git
require 'jrubyfx'
require 'matrix'

DELTA, STILL = 300.0, Vector[0.0, 0.0]
MOVES = { LEFT: Vector[-DELTA, 0], RIGHT: Vector[DELTA, 0],
         UP: Vector[0, -DELTA], DOWN: Vector[0, DELTA] }
MOVES.default = STILL

class Sprite
  include JRubyFX::DSL
  include JRubyFX::DSLControl
  attr_accessor :position, :velocity
  attr_reader :sprite_image

  def initialize(filename)
    @sprite_image, @position, @velocity = image(filename), Vector[0, 0], STILL
  end

  def update(time)
    @position += (velocity * time)
  end

  def render(graphic)
    graphic.draw_image(sprite_image, *position)
  end

  def boundary
    half_width = sprite_image.width / 2 # looks a bit silly at full width
    half_height = sprite_image.height / 2
    javafx.geometry.Rectangle2D.new(*position, half_width, half_height)
  end

  def intersects?(other)
    other.boundary.intersects boundary
  end
end

class BagGame < JRubyFX::Application
  WIDTH, HEIGHT = 512, 512
  attr_reader :bags
  def start(stage)
    input, @bags = {}, []
    setup_bags
    briefcase = sprite('briefcase.png', position: Vector[200, 0])
    graphic = nil
    with(stage, title: 'Collect the Money Bags!') do
      stage.layout_scene(WIDTH, HEIGHT) do
        group do
          canvas(WIDTH, HEIGHT) do
            graphic = graphicsContext2D
            with(graphic, fill: Color::GREEN, stroke: Color::BLACK)
          end
        end
      end
    end.show

    stage.scene.on_key_pressed { |event| input[event.code.to_s.to_sym] = true }
    stage.scene.on_key_released { |event| input.delete(event.code.to_s.to_sym) }

    ActionTimer.new(self, briefcase, bags, graphic, input).start
  end

  def setup_bags
    15.times do
      bags << sprite(
        'moneybag.png',
        position: Vector[rand(50..400), rand(50..400)]
      )
    end
  end
end

class ActionTimer < javafx.animation.AnimationTimer
  attr_reader :bags

  def initialize(game, briefcase, bags, graphic, input)
    super()
    @game, @briefcase, @bags, @graphic, @input = game, briefcase, bags, graphic, input
    @last_time, @score = java.lang.System.nanoTime, 0
  end

  def handle(time)
    # game logic (you can press left + up to move diagonal)
    total = @input.keys.map { |move| MOVES[move] }.reduce(:+)
    @briefcase.velocity = total || STILL
    @briefcase.update((time - @last_time) / 1_000_000_000.0)
    @last_time = time
    bags_count = bags.size # collision detection
    bags.delete_if { |bag| @briefcase.intersects? bag }
    @score += bags_count - bags.size
    @graphic.clear_rect 0, 0, 512, 512 # rendering!
    @briefcase.render @graphic
    @game.setup_bags if bags.empty?
    bags.each { |moneybag| moneybag.render @graphic }
    @graphic.stroke_text "Cash: $#{100 * @score}", 360, 36
  end
end

BagGame.launch
