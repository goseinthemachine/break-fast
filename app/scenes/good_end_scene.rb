class GoodEndScene
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
    outputs.labels << { x:  10, y: 700, text: "You escaped from the truck just in time." }
    outputs.labels << { x:  10, y: 670, text: "Now you can fulfil your true destiny." }
    outputs.labels << { x:  10, y: 650, text: "To have your sweet innards eaten by children." }
    outputs.labels << { x:  10, y: 625, text: "You are BREAK FAST!" }
    outputs.sprites << { x: 500, y: 10, w: 700, h: 700, path: 'sprites/good_ending.jpeg' }
    outputs.labels << { x:  10, y: 60, text: "Press esc to go back to main menu" }
  end
end