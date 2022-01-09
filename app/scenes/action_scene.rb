require 'app/scenes/good_end_scene.rb'
require 'app/scenes/bad_end_scene.rb'

class ActionScene
  attr_accessor :inputs, :state, :outputs, :args
  def initialize(args)
    self.args = args
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

  def render_notice
    if state.notice.duration < 10
      state.notice.duration += 1 if state.start.at.elapsed_time % 60 == 0
      if state.notice.duration % 2 == 1
        outputs.sprites << [x: 975, y: 500, w: 250, h: 250, path: 'sprites/break.png']
      end
    end
  end

  def render

    if state.debug.show_hitboxes
      outputs.primitives  << state.door.hurtbox.solid!
    end
    outputs.labels << [540, 50, "Time Left:"]
    outputs.labels << [580, 25, "#{ state.time_left }"]

    render_background
    render_notice

    door = {
      x: 1020,
      y: -10,
      w: 500,
      h: 1000,
      path: state.door.frame
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
    outputs.solids  << [530, 320, 50, 50]
  end

  def handle_player_movement
    if inputs.controller_one.left_analog_x_perc > 0 || inputs.keyboard.d
      if state.player.dx < state.player_max_run_speed
        state.player.dx += if state.player.y > state.bridge_top
                             0.2 * state.player_acceleration
                           else
                             state.player_acceleration
                           end
      end
    elsif inputs.controller_one.left_analog_x_perc < 0 || inputs.keyboard.a
      if state.player.dx > -state.player_max_run_speed
        state.player.dx += if state.player.y > state.bridge_top
                             0.2 * -state.player_acceleration
                           else
                             -state.player_acceleration
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
      if inputs.controller_one.key_down.y || inputs.keyboard.key_down.space || inputs.keyboard.key_down.w
        state.player.dy = 15
        state.player.jump.at ||= state.tick_count
        outputs.sounds << "sounds/box-landing.wav"
      end
    end

    if inputs.controller_one.key_up.y || inputs.keyboard.key_up.space
      state.player.jump.at = nil
    end
    if inputs.controller_one.key_down.x || inputs.keyboard.key_down.j
      state.player.state = :attacking
      state.player.attack.at ||= state.tick_count
      if state.player.falling
        state.player.attack_state = :nair
      elsif  inputs.controller_one.left_analog_x_perc.abs > 0 || inputs.keyboard.d || inputs.keyboard.a
        state.player.attack_state = :fattack
      else
        state.player.attack_state = :nattack
      end


    end
  end

  def calc_attack

    case state.player.attack_state
    when :nattack
      state.player.attack.hitbox = {
        x: state.player.x + (state.player.w/2 - 12.5) + (state.player.flip_horizontally ?  -50 : +50),
        y: state.player.y + (state.player.h/2 - 12.5) + 45,
        w: 25,
        h: 25,
        r: 255,
        g: 0,
        b: 0,
        a: 75
      }
      state.player.dx = 0
      if state.player.attack.at.elapsed_time > state.player.attack.nattack_duration
        state.player.state = :standing
        state.player.attack.at = nil
        state.player.attack_state = nil
      end
    when :nair
      state.player.attack.hitbox = {
        x: state.player.x,
        y: state.player.y,
        w: state.player.w,
        h: state.player.h,
        r: 255,
        g: 0,
        b: 0,
        a: 75
      }
      if state.player.attack.at.elapsed_time > state.player.attack.nair_duration
        state.player.state = :jumping
        state.player.attack.at = nil
        state.player.attack_state = nil
      end
    when :fattack
      state.player.attack.hitbox = {
        x: state.player.x + (state.player.w/2) + (state.player.flip_horizontally ?  -60 : 10),
        y: state.player.y,
        w: 50,
        h: state.player.h,
        r: 255,
        g: 0,
        b: 0,
        a: 75
      }

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
    state.player.action.at = nil unless state.player.falling
  end

  def calc_sprite_frame
    state.player.frame =
      if state.player.state == :attacking
        case state.player.attack_state
        when :nattack
          frame = (state.player.attack.at.elapsed_time % state.player.attack.nattack_duration).to_s.rjust(4, '0')
          "sprites/box_nattack#{frame}.png"
        when :nair
          frame = (state.player.attack.at.elapsed_time % state.player.attack.nair_duration).to_s.rjust(4, '0')
          "sprites/box_nair#{frame}.png"
        when :fattack
          frame = (state.player.attack.at.elapsed_time % state.player.attack.fattack_duration).to_s.rjust(4, '0')
          "sprites/box_fattack#{frame}.png"
        end

      else
        case(state.player.state)
        when :standing
          'sprites/frame0000.png'
        when :running
          if state.tick_count % 20 == 0
            outputs.sounds << "sounds/box-walking.wav"
          end
          "sprites/frame000#{state.tick_count % 10}.png"
        when :jumping
          'sprites/jumping0000.png'
        when :nair
        when :nattack
        else
          'sprites/frame0000.png'
        end
      end
  end

  def calc_hit

    case state.player.attack_state
    when :nattack
      frame = state.player.attack.at.elapsed_time % state.player.attack.nattack_duration
      if frame == 10
        if state.door.hurtbox.intersect_rect?(state.player.attack.hitbox, 0.0)
          hit_door 1
          if state.debug.show_hitboxes
            outputs.primitives  << state.player.attack.hitbox.solid!
          end
        end
      end
    when :nair
      frame = state.player.attack.at.elapsed_time % state.player.attack.nair_duration
      if frame == 10
        if state.door.hurtbox.intersect_rect?(state.player.attack.hitbox, 0.0)
          hit_door 3
          if state.debug.show_hitboxes
            outputs.primitives  << state.player.attack.hitbox.solid!
          end
        end
      end
    when :fattack
      frame = state.player.attack.at.elapsed_time % state.player.attack.fattack_duration
      if frame == 20
        if state.door.hurtbox.intersect_rect?(state.player.attack.hitbox, 0.0)
          hit_door 10
          if state.debug.show_hitboxes
            outputs.primitives  << state.player.attack.hitbox.solid!
          end
        end
      end

    end
  end

  def hit_door dmg
    state.door.hp -= dmg
    if dmg > 5
      outputs.sounds << "sounds/door-bang.wav"
    else
      outputs.sounds << "sounds/door-tap.wav"
    end
  end

  def calc_door_frame
    if state.door.hp > 50
      state.door.frame = 'sprites/door0000.png'
    elsif state.door.hp <= 0
      $active_scene = GoodEndScene.new(self.args)
    else
          state.door.frame = 'sprites/door0001.png'
    end
  end

  def calc_time_left
    if state.start.at.elapsed_time % 60 == 0
      state.time_left -= 1
      if state.time_left > 1
        state.notice.at = state.tick_count
      end
    end

    if state.time_left <= 0
      $active_scene = BadEndScene.new(self.args)
    end
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

    calc_sprite_frame

    calc_hit

    calc_door_frame

    calc_time_left

  end

  def defaults
    fiddle

    state.tick_count = state.tick_count
    state.bridge_top = 64
    state.bridge_end = 1270
    state.start.at ||= state.tick_count
    state.player.x  ||= 0                        # initializes player's properties
    state.player.y  ||= state.bridge_top
    state.player.w  ||= 128
    state.player.h  ||= 128
    state.player.dy ||= 0
    state.player.dx ||= 0
    state.player.r  ||= 0
    state.player.flip_horizontally ||= false
    state.player.frame ||= 'sprites/frame0000.png'
    state.door.frame ||= 'sprites/door0000.png'
    state.player.max_dx ||= 10
    state.player.state ||= :standing
    state.game_over_at ||= 0
    state.animation_time || state.timeleft ||=0
    state.timeright ||=0
    state.lastpush ||=0
    state.time_left ||= 20
    state.notice.duration ||= 0
    state.notice.at = nil
    state.door.hurtbox ||= {
      x: 1230,
      y: 50,
      w: 50,
      h: 720,
      r: 0,
      g: 0,
      b: 255,
      a: 75
    }

  end

  def reset
    state.player.x  = 0  # initializes player's properties
    state.player.y  = state.bridge_top
    state.player.dy = 0
    state.player.dx = 0
    state.player.r  = 0
    state.player.state = :standing
    state.door.hp = 100
    state.player.attack_state = nil
    state.player.attack.at = nil
    state.player.state = nil
    state.start.at = nil
    state.time_left = 20
    state.notice.duration = 0
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
    state.player.attack.nattack_duration = 12
    state.player.attack.fattack_duration = 28
    state.player.attack.nair_duration = 12
    state.player.action.jump_duration = 5
    state.debug.show_hitboxes = false
    state.player.attack.hitbox ||= nil
    state.door.hp ||= 100

  end

end
