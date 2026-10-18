Bob = Particle:extend()


function Bob:new(scene, pos, radius)
    self.radius = radius
    self.start_ttl = rnd(50) + 30
    Bob.super.new(self, scene.particles_bg, pos, vec(symrnd(.2), symrnd(.2)), self.start_ttl)
end


function Bob:draw()
    local ratio = self.ttl/self.start_ttl
    local ratio2 = (self.ttl+8)/self.start_ttl
    local radius = self.radius*(-4*ratio*(ratio - 1))
    local radius2 = (self.radius-2)*(-4*ratio2*(ratio2 - 1))
    for pos in all(get_wrapped_positions(self.pos, 128*8, 64*8)) do
        circfill(pos.x, pos.y, radius, 12)
        circfill(pos.x, pos.y, radius2, 1)
    end
end
