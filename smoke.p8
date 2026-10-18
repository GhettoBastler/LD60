Smoke = Particle:extend()

Smoke.COLORS_WHITE = {5, 13, 6, 7}
Smoke.COLORS_BLACK = {13, 5, 2, 0}
Smoke.THRESHOLDS = {20, 30, 40}

function Smoke:new(scene, pos, black)
    self.start_ttl = 50 + rnd(20)
    self.black = black
    self.DRAG = self.black and .95 or .8
    Smoke.super.new(self, scene.particles_fg, pos, vec(symrnd(1), -2+symrnd(1)), self.start_ttl)
end


function Smoke:update()
    if self.black then
        self.vel.y -= .05
    end
    Smoke.super.update(self)
end


function Smoke:draw()
    local patterns = {0x7fdf.8, 0x5f5f.8, 0x5a5a.8, 0x0000.8}
    local colors = self.black and self.COLORS_BLACK or self.COLORS_WHITE
    local picked = #colors
    for i=1, #self.THRESHOLDS do
        if self.ttl <= self.THRESHOLDS[i] then
            picked = i
            break
        end
    end
    local t = 1 - self.ttl/self.start_ttl
    local radius = 10*(1 - (t - 1)^4)
    fillp(patterns[picked])
    for pos in all(get_wrapped_positions(self.pos, 128*8, 64*8)) do
        circfill(pos.x, pos.y, radius, colors[picked])
    end
    fillp()
end
