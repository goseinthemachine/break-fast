class ActionScene
  attr_accessor :inputs, :state, :outputs
  def initialize(args)
    self.inputs = args.inputs
    self.state = args.state
    self.outputs = args.outputs
  end

  # Calls the methods necessary for the app to run successfully.
  def tick
    defaults
    render
    handle_input
    calc
  end

  def render_background
    outputs.sprites << [x: 0, y: 0, w: 1280, h: 720, path: 'sprites/background.png']
  end

  def render
    outputs.labels  << [580, 500, inputs.controller_one.left_analog_x_perc, 5, 1]
    outputs.labels  << [580, 460, inputs.controller_one.left_analog_y_perc, 5, 1]
    outputs.labels  << [640, 500, inputs.controller_one.right_analog_x_perc, 5, 1]
    outputs.labels  << [640, 460, inputs.controller_one.right_analog_y_perc, 5, 1]
    outputs.labels  << [640, 420, "attack: #{state.player.attack_state} state: #{state.player.state}", 5, 1]
    outputs.labels  << [640, 390, "jump elapsed time: #{state.player.jump.at ? state.player.jump.at.elapsed_time : ''}", 5, 1]
    outputs.labels  << [640, 360, "attack elapsed time: #{state.player.attack.at ? state.player.attack.at.elapsed_time : ''}", 5, 1]

    render_background

    door = {
      x: 1020,
      y: -10,
      w: 500,
      h: 1000,
      path: 'sprites/door0000.png'
    }

    player = {
      x: state.player.x,
      y: state.player.y,
      w: state.player.w,
      h: state.player.h,
      path: state.player.frame,
      flip_horizontally: state.player.flip_horizontally
    }

    outputs.sprites << door

    outputs.sprites << player

  end

  def handle_player_movement
    if inputs.controller_one.left_analog_x_perc > 0
      if state.player.dx < state.player_max_run_speed
        state.player.dx += if state.player.y > state.bridge_top
                             0.2 * inputs.controller_one.left_analog_x_perc
                           else
                             inputs.controller_one.left_analog_x_perc
                           end
      end
    elsif inputs.controller_one.left_analog_x_perc < 0
      if state.player.dx > -state.player_max_run_speed
        state.player.dx += if state.player.y > state.bridge_top
                             0.2 * inputs.controller_one.left_analog_x_perc
                           else
                             inputs.controller_one.left_analog_x_perc
                           end
      end
    else
      state.player.dx *= if state.player.y > state.bridge_top
                           state.air_friction
                         else
                           state.friction
                         end

    end
  end

  def handle_input
    if state.player.state != :attacking
      handle_player_movement
    end

    if !state.player.falling
      if inputs.controller_one.key_down.y
        state.player.dy = 15
        state.player.jump.at ||= state.tick_count
      end
    end

    if inputs.controller_one.key_up.y
      state.player.jump.at = nil
    end
    if inputs.controller_one.key_down.x
      state.player.state = :attacking
      state.player.attack.at ||= state.tick_count
      if state.player.falling
        state.player.attack_state = :nair
      elsif  inputs.controller_one.left_analog_x_perc.abs > 0
        state.player.attack_state = :fattack
      else
        state.player.attack_state = :nattack
      end


    end
  end

  def calc_attack
    case state.player.attack_state
    when :nattack
      state.player.dx = 0
      if state.player.attack.at.elapsed_time > state.player.attack.nattack_duration
        state.player.state = :standing
        state.player.attack.at = nil
        state.player.attack_state = nil
      end
    when :nair
      if state.player.attack.at.elapsed_time > state.player.attack.nair_duration
        state.player.state = :jumping
        state.player.attack.at = nil
        state.player.attack_state = nil
      end
    when :fattack
      if state.player.attack.at.elapsed_time > state.player.attack.fattack_duration
        state.player.state = :standing
        state.player.attack.at = nil
        state.player.attack_state = nil
      end
    end
  end

  def calc_x
    state.player.x += state.player.dx
    state.player.x  = state.player.x.greater(0)
    if state.player.x >= state.bridge_end - state.player.w ||
      state.player.x <= 0
      state.player.dx = 0
    end
    state.player.x = state.player.x.lesser(state.bridge_end - state.player.w)

    #state.player.rect = [state.player.x, state.player.y, state.player.h, state.player.w] # sets definition for player

    if state.player.state == :running && state.player.dx.abs > 0
      state.player.flip_horizontally = state.player.dx <= 0
    end
  end

  def calc_y
    if state.player.y > state.bridge_top && state.player.state != :attacking
      state.player.state = :jumping
    end
    state.player.y  += state.player.dy
    state.player.dy += state.gravity
    state.player.y  = state.player.y.greater(state.bridge_top)
    # player is not falling if it is located on the top of the bridge
    state.player.falling = state.player.y > state.bridge_top
  end

  def calc
    if state.player.state == :attacking && state.player.falling
      calc_x
      calc_attack
    elsif state.player.state == :attacking
      calc_attack
    else
      # Since velocity is the change in position, the change in x increases by dx. Same with y and dy.
      if state.player.dx.abs < 0.1
        state.player.state = :standing
        state.player.dx = 0
      else
        state.player.state = :running
      end

      calc_x

    end

    calc_y

    state.player.frame =
      case(state.player.state)
      when :standing
        'sprites/frame0000.png'
      when :running
        "sprites/frame000#{state.tick_count % 10}.png"
      when :jumping
        'sprites/jumping0000.png'
      when :nair
      when :nattack
      else
        'sprites/frame0000.png'
      end
  end

  def defaults
    fiddle

    state.tick_count = state.tick_count
    state.bridge_top = 64
    state.bridge_end = 1270
    state.player.x  ||= 0                        # initializes player's properties
    state.player.y  ||= state.bridge_top
    state.player.w  ||= 128
    state.player.h  ||= 128
    state.player.dy ||= 0
    state.player.dx ||= 0
    state.player.r  ||= 0
    state.player.flip_horizontally ||= false
    state.player.frame ||= 'sprites/frame0000.png'
    state.player.max_dx ||= 10
    state.player.state ||= :standing
    state.game_over_at ||= 0
    state.animation_time || state.timeleft ||=0
    state.timeright ||=0
    state.lastpush ||=0

  end

  def reset
    state.player.x  = 0  # initializes player's properties
    state.player.y  = state.bridge_top
    state.player.dy = 0
    state.player.dx = 0
    state.player.r  = 0
    state.player.state = :standing
  end

  def fiddle
    state.gravity                     = -0.5
    state.friction                    = 0.7
    state.air_friction                = 0.99
    state.player_jump_power           = 10      # sets player values
    state.player_jump_power_duration  = 5
    state.player_max_run_speed        = 10
    state.player_speed_slowdown_rate  = 0.9
    state.player_acceleration         = 0.9
    state.player.attack.nattack_duration = 5
    state.player.attack.fattack_duration = 10
    state.player.attack.nair_duration = 5
    state.player.action.jump_duration = 5
  end

end
