require 'mygame/app/scenes/action_scene.rb'
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
    outputs.labels << { x:  10, y: 60, text: "Press START to begin" }
  end

  def handle_input
    if inputs.controller_one.key_held.start
      $active_scene = ActionScene.new(@args)
      $active_scene.reset
    end
  end
end