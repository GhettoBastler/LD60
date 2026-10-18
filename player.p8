Player = Object:extend()


Player.BUMP_FACTOR = .5
Player.DIAG_BUMP_FACTOR = .9
Player.BOB_DELAY = 5

Player.HEIGHT = 6
Player.WIDTH = 6
Player.OFFSET = vec(-4,-4)

Player.GEARS = {-.01, 0, .01, .015}
Player.DRAG = .99
Player.SIDE_DRAG = .8
Player.STUN_DURATION = 90

Player.SMOKE_DELAYS = {7, 0, 7, 5, 4}
Player.PIER_THRESHOLD = 4

Player.SPRITE_LAYERS = {64,96,66}
Player.SPRITE_SUNK = 98
Player.SINK_DURATION = 120

Player.HEALTH = 3


function Player:new(scene)
    self.scene = scene
end


function Player:init(position)
    self.pos = vcpy(position)
    self.vel = vec()
    self.va = 0
    self.angle = 0
    self.remainder = vec()
    self.health = self.HEALTH
    self.hit_timer = 0
    self.bob_timer = 0
    self.state = "alive"
    self.smoke_timer = 0
    self.gear = 2
    self.carrying = false
end


function Player:move(axis, amount, on_collide)
    self.remainder[axis] += amount
    local move = round(self.remainder[axis])
    if move != 0 then
        self.remainder[axis] -= move
        local sign = sgn(move)
        while move != 0 do
            local collided = self:check_collision(axis, sign)
            if collided then
                if on_collide then
                    on_collide(self, axis, sign, collided)
                end
                break
            else
                self.pos[axis] += sign
                move -= sign
            end
        end
    end
end


function Player:check_collision(axis, sign)
    local x_a, y_a, x_b, y_b
    if axis == "x" then
        x_a = self.pos.x + (self.WIDTH-1)/2 + sign*(self.WIDTH+1)/2 + self.OFFSET.x
        y_a = self.pos.y + self.OFFSET.y
        x_b = x_a
        y_b = y_a + self.HEIGHT - 1
    elseif axis == "y" then
        x_a = self.pos.x + self.OFFSET.x
        y_a = self.pos.y + (self.HEIGHT-1)/2 + sign*(self.HEIGHT+1)/2 + self.OFFSET.y
        x_b = x_a + self.WIDTH - 1
        y_b = y_a
    end
    if fget(mget(x_a\8, y_a\8)) & 15 == 1 or fget(mget(x_b\8, y_b\8)) & 15 == 1 then
        return 1
    else
        -- diagonals
        if axis == "x" then
            if sign > 0 then
                if fget(mget(x_a\8, y_a\8)) & 11 == 11 then
                    if (x_a % 8) - (y_a % 8) >= -1 then
                        return 11
                    end
                elseif fget(mget(x_b\8, y_b\8)) & 3 == 3 then
                    if (x_b % 8) + (y_b % 8) >= 7 then
                        return 3
                    end
                end
            else
                if fget(mget(x_a\8, y_a\8)) & 15 == 15 then
                    if (x_a % 8) + (y_a % 8) <= 7 then
                        return 15
                    end
                elseif fget(mget(x_b\8, y_b\8)) & 7 == 7 then
                    if -(x_b % 8) + (y_b % 8) >= -1 then
                        return 7
                    end
                end

            end
        else
            if sign > 0 then
                if fget(mget(x_a\8, y_a\8)) & 7 == 7 then
                    if -(x_a % 8) + (y_a % 8) >= -1 then
                        return 7
                    end
                elseif fget(mget(x_b\8, y_b\8)) & 3 == 3 then
                    if (x_b % 8) + (y_b % 8) >= 7 then
                        return 3
                    end
                end
            else
                if fget(mget(x_a\8, y_a\8)) & 15 == 15 then
                    if (x_a % 8) + (y_a % 8) <= 7 then
                        return 15
                    end
                elseif fget(mget(x_b\8, y_b\8)) & 11 == 11 then
                    if (x_b % 8) - (y_b % 8) >= -1 then
                        return 11
                    end
                end
            end
        end
    end
end


function Player:bump(axis, sign, collided)
    sfx(10)
    for i=1, 100 do
        Splash(self.scene, self.pos, vadd(vrot(vec(-100*self.GEARS[self.gear], 0), self.angle), vec(symrnd(2), -rnd(3)-2)))
    end
    -- check hit
    if self.state == "alive" and abs(self.vel[axis]) > 0.5 and self.hit_timer <= 0 then
        self:hit()
    end
    if collided == 1 then
        self.vel = vmul(self.vel, self.BUMP_FACTOR)
        self.vel[axis] = -sign*abs(self.vel[axis])
        if angle == "x" then
            if self.angle > 0 and self.angle < .5 then
                self.va += sign*0.02
            elseif self.angle > .5 then
                self.va -= sign*0.02
            end
        else
            if self.angle > .75 or self.angle < .25 then
                self.va += sign*0.02
            elseif self.angle > .25 and self.angle < .75 then
                self.va -= sign*0.02
            end
        end
    else
        -- diagonals
        self.vel = vmul(self.vel, self.DIAG_BUMP_FACTOR)
        if collided == 3 then
            if axis == "x" then
                self.vel.y = -self.vel.x
                self.vel.x = 0
                self.va += 0.02
            else
                self.vel.x = -self.vel.y
                self.vel.y = 0
                self.va -= 0.02
            end
        elseif collided == 7 then
            if axis == "x" then
                self.vel.y = self.vel.x
                self.vel.x = 0
                -- self.angle -= 0.02
                self.va -= 0.02
            else
                self.vel.x = self.vel.y
                self.vel.y = 0
                -- self.angle += 0.02
                self.va += 0.02
            end
        elseif collided == 11 then
            if axis == "x" then
                self.vel.y = self.vel.x
                self.vel.x = 0
                -- self.angle -= 0.02
                self.va -= 0.02
            else
                self.vel.x = self.vel.y
                self.vel.y = 0
                -- self.angle += 0.02
                self.va += 0.02
            end
        elseif collided == 15 then
            if axis == "x" then
                self.vel.y = -self.vel.x
                self.vel.x = 0
                -- self.angle += 0.02
                self.va += 0.02
            else
                self.vel.x = -self.vel.y
                self.vel.y = 0
                -- self.angle -= 0.02
                self.va -= 0.02
            end
        end
    end
end


function Player:hit()
    sfx(9)
    self.hit_timer = self.STUN_DURATION
    self.health -= 1
    self.gear = 2
    if self.health <= 0 then
        self:kill()
    end
end


function Player:update()
    if self.state == "alive" then
        if self.bob_timer > 0 then
            self.bob_timer -= 1
        else
            self.bob_timer = self.BOB_DELAY
            Bob(self.scene, vadd(self.pos, vmul(self.vel, 7)), 8*taxicab(self.vel))
        end
        self.hit_timer = max(0, self.hit_timer - 1)
        if btn(0) then
            self.va += .001
        elseif btn(1) then
            self.va -= .001
        end

        -- rotation
        self.va *= 0.8
        self.angle += self.va
        self.angle %= 1

        -- stop side movement
        local nv = vrot(vec(0, self.SIDE_DRAG), self.angle)
        self.vel = vsub(self.vel, vmul(nv, dotprod(nv, self.vel)))

        local prev_gear = self.gear
        if btnp(2) then
            -- speed up
            self.gear = min(#self.GEARS, self.gear + 1)
        elseif btnp(3) then
            -- slow down
            self.gear = max(1, self.gear - 1)
        end
        if self.gear != prev_gear then
            sfx(15)
        end
        self.vel = vadd(self.vel, vrot(vec(self.GEARS[self.gear], 0), self.angle))

        -- drag
        self.vel = vmul(self.vel, self.DRAG)

        if self.gear != 2 then
            if self.smoke_timer <= 0 then
                sfx(8)
                local chimney = vadd(self.pos, vrot(vec(-3, 0), self.angle))
                for i=1, 5 do
                    Smoke(self.scene, vadd(chimney, vec(0, -#self.SPRITE_LAYERS)))
                end
                self.smoke_timer = self.SMOKE_DELAYS[self.gear]
            else
                self.smoke_timer -= 1
            end
        end

        self:move("x", self.vel.x, self.bump)
        self:move("y", self.vel.y, self.bump)

        -- wrap position
        self.pos.x %= 128*8
        self.pos.y %= 64*8
        -- printh(self.pos.x.." "..self.pos.y)
    elseif self.state == "stopping" then
        self.vel = vmul(self.vel, self.DRAG)
        self:move("x", self.vel.x, self.bump)
        self:move("y", self.vel.y, self.bump)

        -- wrap position
        self.pos.x %= 128*8
        self.pos.y %= 64*8
    elseif self.state == "sinking" then
        self.vel = vec()
        self.va = 0
        if self.sink_timer > 0 then
            self.sink_timer -= 1
        else
            self.state = "sunk"
        end
        Smoke(self.scene, self.pos, true)
    end
end


function Player:draw()
    if self.state != "sinking" and self.state != "sunk" then
        if self.hit_timer % 8 <= 4 then
            self:draw_ship(self.pos, self.angle)
        end
    else
        spr(self.SPRITE_SUNK, self.pos.x-8, self.pos.y-8, 2, 2)
    end
    -- hitbox
    if DEBUG then
        rrectfill(self.pos.x+self.OFFSET.x, self.pos.y+self.OFFSET.y, self.WIDTH, self.HEIGHT, 0, 10)
    end
end


function Player:kill()
    self.state = "sinking"
    self.sink_timer = self.SINK_DURATION
    sfx(13)
end


function Player:is_sunk()
    return self.state == "sunk"
end


function Player:is_hit()
    return self.hit_timer > 0
end


function Player:pickup()
    sfx(11)
    self.carrying = true
end

function Player:drop(level)
    printh(level)
    self.carrying = false
    local sfx_len
    if level == 1 then
        sfx_len = 1
    elseif level == 2 then
        sfx_len = 2
    elseif level == 3 then
        sfx_len = 3
    else
        sfx_len = 7
    end

    sfx(12, -1, 0, sfx_len)
end


function Player:get_pier()
    for pier in all(self.scene.piers) do
        if taxicab(vsub(pier, self.pos)) < self.PIER_THRESHOLD*8 then
            return pier
        end
    end
end


function Player:stop()
    self.state = "stopping"
end


function Player:draw_ship(pos, angle)
    for i, layer in ipairs(self.SPRITE_LAYERS) do
        local sx,sy=(layer%16)*8,(layer\16)*8
        rspr(sx,sy,112,48,-angle,2)
        sspr(112,48,16,16,pos.x-8,pos.y-8-i)
    end
end
