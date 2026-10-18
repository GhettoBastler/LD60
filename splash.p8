Splash = Particle:extend()

Splash.DRAG = .95

function Splash:new(scene, pos, vel)
    Splash.super.new(self, scene.particles_fg, pos, vel, 5+rnd(10))
end


function Splash:update()
    self.vel.y += .5
    Splash.super.update(self)
end


function Splash:draw()
    pset(self.pos.x, self.pos.y, self.ttl <= 5 and 7 or 12)
end
