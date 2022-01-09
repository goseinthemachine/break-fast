require 'app/require.rb'

def tick args
    if $active_scene.nil?
        $active_scene ||= MenuScene.new(args)
    else
        $active_scene.tick
    end

    handle_input args
end

def handle_input args
    if args.inputs.controller_one.key_held.select || args.inputs.keyboard.key_down.escape
        $active_scene = MenuScene.new(args)
    end
end