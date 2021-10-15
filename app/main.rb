def render_background args
  args.outputs.sprites << [x: 0, y: 0, w: 1280, h: 720, path: 'sprites/background.png']
end

def render args
  args.outputs.labels  << [580, 500, args.inputs.controller_one.left_analog_x_perc, 5, 1]
  args.outputs.labels  << [580, 460, args.inputs.controller_one.left_analog_y_perc, 5, 1]
  args.outputs.labels  << [640, 500, args.inputs.controller_one.right_analog_x_perc, 5, 1]
  args.outputs.labels  << [640, 460, args.inputs.controller_one.right_analog_y_perc, 5, 1]
  args.outputs.labels  << [640, 420, "v:#{args.state.player.dx}", 5, 1]
  args.outputs.sprites << [x: 0, y: 0, w: 1280, h: 720, path: 'sprites/background.png']

  render_background args

  player = [args.state.player.x, args.state.player.y,
            args.state.player.w, args.state.player.h,
            "sprites/square/white.png",
            args.state.player.r]
  args.outputs.sprites << player

end

def input args
  # TODO: Add acceleration with cap
  if args.inputs.controller_one.left_analog_x_perc > 0
    if args.state.player.dx < args.state.player_max_run_speed
      if args.state.player.y > args.state.bridge_top
        args.state.player.dx += 0.2 * args.inputs.controller_one.left_analog_x_perc
      else
        args.state.player.dx += args.inputs.controller_one.left_analog_x_perc
      end
    end
  elsif args.inputs.controller_one.left_analog_x_perc < 0
    if args.state.player.dx > -args.state.player_max_run_speed
      if args.state.player.y > args.state.bridge_top
        args.state.player.dx += 0.2 * args.inputs.controller_one.left_analog_x_perc
      else
        args.state.player.dx += args.inputs.controller_one.left_analog_x_perc
      end
    end
  else
    if args.state.player.y > args.state.bridge_top
      args.state.player.dx *= args.state.air_friction
    else
      args.state.player.dx *= args.state.friction
    end

  end


  if args.inputs.controller_one.key_held.y && args.state.player.y <= args.state.bridge_top
    args.state.player.dy = 15
  end
end

def calc args
  # Since velocity is the change in position, the change in x increases by dx. Same with y and dy.
  if args.state.player.dx.abs < 0.1
    args.state.player.dx = 0
  end
  args.state.player.x  += args.state.player.dx
  args.state.player.y  += args.state.player.dy

  # Since acceleration is the change in velocity, the change in y (dy) increases every frame
  args.state.player.dy += args.state.gravity

  # player's y position is either current y position or y position of top of
  # bridge, whichever has a greater value
  # ensures that the player never goes below the bridge
  args.state.player.y  = args.state.player.y.greater(args.state.bridge_top)

  # player's x position is either the current x position or 0, whichever has a greater value
  # ensures that the player doesn't go too far left (out of the screen's scope)
  args.state.player.x  = args.state.player.x.greater(0)
  if args.state.player.x >= args.state.bridge_end - args.state.player.w ||
    args.state.player.x <= 0
    args.state.player.dx = 0
  end
  args.state.player.x = args.state.player.x.lesser(args.state.bridge_end - args.state.player.w)

  # player is not falling if it is located on the top of the bridge
  args.state.player.falling = false if args.state.player.y == args.state.bridge_top
  #args.state.player.rect = [args.state.player.x, args.state.player.y, args.state.player.h, args.state.player.w] # sets definition for player
end

def tick args
  defaults args
  render args
  input args
  calc args
end

def defaults args
  fiddle args

  args.state.tick_count = args.state.tick_count
  args.state.bridge_top = 128
  args.state.bridge_end = 1280
  args.state.player.x  ||= 0                        # initializes player's properties
  args.state.player.y  ||= args.state.bridge_top
  args.state.player.w  ||= 64
  args.state.player.h  ||= 64
  args.state.player.dy ||= 0
  args.state.player.dx ||= 0
  args.state.player.r  ||= 0
  args.state.player.max_dx ||= 10
  args.state.game_over_at ||= 0
  args.state.animation_time ||=0

  args.state.timeleft ||=0
  args.state.timeright ||=0
  args.state.lastpush ||=0

  args.state.inputlist ||=  ["j","k","l"]
end

def fiddle args
  args.state.gravity                     = -0.5
  args.state.friction                    = 0.7
  args.state.air_friction                = 0.99
  args.state.player_jump_power           = 10      # sets player values
  args.state.player_jump_power_duration  = 5
  args.state.player_max_run_speed        = 10
  args.state.player_speed_slowdown_rate  = 0.9
  args.state.player_acceleration         = 0.9
end
