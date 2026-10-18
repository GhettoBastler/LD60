title_scene = Scene:extend()


title_scene.WAVE_DELAY = 120


function title_scene:init()
    music()
    self.angle = 0
    self.wave_timer = 0
end

function title_scene:update()
    if self.wave_timer > 0 then
        self.wave_timer -= 1
    else
        self.wave_timer = self.WAVE_DELAY
    end

    self.angle += .005
    self.angle %= 1
    if btnp(4) then
        music(-1)
        transitions.circle_out(vec(64, 64), 60)
        intro_scene:enter()
        transitions.circle_in(vec(64, 64), 60)
    end
end


function title_scene:draw()
    cls(1)
    -- wave
    local radius = 100*(1-(self.wave_timer / self.WAVE_DELAY)^2)
    circ(64, 64, radius, 12)
    cprint("steam dasher", 2, 18, 0, true)
    cprint("steam dasher", 0, 16, 7, true)

    Player:draw_ship(vec(64, 64+3*sin(t())), self.angle)

    if t() % 1 < .5 then
        print("press 🅾️ to start", 30, 100, 10)
    end

    print("BY GHETTOBASTLER", 63, 115, 13)
    print("MADE IN 48H FOR LD60", 47, 121, 13)
end
