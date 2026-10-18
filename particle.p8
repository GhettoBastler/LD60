Particle = Object:extend()

Particle.DRAG = 0.8

function Particle:new(pool, pos, vel, ttl)
    self.pool = pool
    self.pos = vcpy(pos)
    self.vel = vcpy(vel)
    self.ttl = ttl
    add(self.pool, self)
end

function Particle:update()
    if self.ttl <= 0 then
        del(self.pool, self)
    else
        self.pos = vadd(self.pos, self.vel)
        self.vel = vmul(self.vel, self.DRAG)
        self.ttl -= 1
    end
end

function Particle:draw()
    pset(self.pos.x, self.pos.y, 8)
end
