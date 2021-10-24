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
    outputs.labels << { x:  10, y: 60, text: "You are BREAK FAST" }
  end
end