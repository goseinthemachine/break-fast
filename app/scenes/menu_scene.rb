require 'app/scenes/action_scene.rb'
class MenuScene
  attr_accessor :inputs, :state, :outputs

  def initialize args
    @args = args
    self.inputs = args.inputs
    self.state = args.state
    self.outputs = args.outputs
  end

  def tick
    render
    handle_input
  end

  def render
    outputs.solids << { x: 0, y: 0, w: 1280, h: 720, r: 255, g: 255, b: 255 }
    outputs.labels << { x:  10, y: 60, text: "Press START/SPACE to begin" }
    outputs.sprites << { x: 500, y: 10, w: 700, h: 700, path: 'sprites/title.jpeg' }
  end

  def handle_input
    if inputs.controller_one.key_held.start || inputs.keyboard.space
      $active_scene = ActionScene.new(@args)
      $active_scene.reset
    end
  end
end