class BadEndScene
  attr_accessor :inputs, :state, :outputs

  def initialize args
    self.inputs = args.inputs
    self.state = args.state
    self.outputs = args.outputs
  end

  def tick
    render
  end

  def render
    outputs.labels << { x:  10, y: 700, text: "You were destroyed when the truck crashed." }
    outputs.labels << { x:  10, y: 680, text: "You have failed." }
    outputs.sprites << { x: 500, y: 10, w: 700, h: 700, path: 'sprites/bad_ending.jpeg' }
    outputs.labels << { x:  10, y: 60, text: "Press esc to go back to main menu" }
  end
end