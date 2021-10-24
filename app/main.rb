require 'mygame/app/require.rb'

def tick args
    if $active_scene.nil?
        $active_scene ||= MenuScene.new(args)
    else
        $active_scene.tick
    end

    handle_input args
end

def handle_input args
    if args.inputs.controller_one.key_held.select
        $active_scene = MenuScene.new(args)
    end
end