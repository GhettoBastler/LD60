game_scene = Scene:extend()


game_scene.DAY_DURATION = 60*60*1.5
-- game_scene.DAY_DURATION = 60*1
game_scene.CRATE_SPRITE = 63
game_scene.ARROW_SPRITE = 51
game_scene.PAY_RATES = {1, 5, 10, 20}
game_scene.END_DURATION = 120

game_scene.player = Player(game_scene)

function game_scene:init()
    self.show_map = false
    self.meter = 1
    self.end_timer = 0
    -- self.released_4 = false
    self.pay = 0
    self.particles_bg = {}
    self.particles_fg = {}
    self.cam_pos = vec()
    self.day_timer = self.DAY_DURATION

    -- check hazards
    self.pier_level = 1
    self.map_level = 0
    self.ice_level = 0

    -- pier level
    if DAY == 2 then
        self.pier_level = 2
    elseif DAY >= 3 then
        self.pier_level = 3
    end
    
    -- ice level
    if DAY >= 6 then
        self.ice_level = 2
    elseif DAY >= 3 then
        self.ice_level = 1
    end

    -- map level
    if DAY >= 7 then
        self.map_level = 2
    elseif DAY >= 4 then
        self.map_level = 1
    end

    reload(0x1000, 0x2000)
    -- change sprite flags
    for i=0, 256 do
        local flag_addr = 0x3000+i
        if @flag_addr & 0x10 == 0x10 and self.ice_level >= 1 then
            -- ice level 1
            poke(flag_addr, @flag_addr + 1)
        elseif @flag_addr & 0x20 == 0x20 and self.ice_level >= 2 then
            -- ice level 2
            poke(flag_addr, @flag_addr + 1)
        -- elseif @flag_addr ==0x80 and self.pier_level >= 2 then
        --     -- pier lvl 2
        --     poke(flag_addr, @flag_addr + 1)
        -- elseif @flag_addr == 0xc0 and self.pier_level >= 3 then
        --     -- pier lvl 3
        --     poke(flag_addr, @flag_addr + 1)
        end
    end

    -- scan map
    self.objectives = {}
    self.piers = {}
    local memidx, curr_byte = 0x8000
    for j=0, 63 do
        for i=0, 127 do
            local flag = fget(mget(i, j))
            if flag == 65 or flag == 129 or flag == 193 then
                -- pier
                local pos = vec(4+i*8, 4+j*8)
                add(self.piers, pos)
                if flag == 65 and self.pier_level >= 1 
                or flag == 129 and self.pier_level >= 2 
                or flag == 193 and self.pier_level >= 3 then
                    add(self.objectives, pos)
                end
            end

            -- set pixel for minimap
            local curr_px
            -- get corresponding pixel value
            if flag == 65 or flag == 129 or flag == 193 then
                -- objective
                curr_px = 15
            elseif flag & 1 == 1 then
                -- solid
                if flag & 0x10 == 0x10 then
                    -- ice 1
                    if self.map_level >= 1 then
                        curr_px = 12
                    else
                        curr_px = 1
                    end
                elseif flag & 0x20 == 0x20 then
                    -- ice 2
                    if self.map_level >= 2 then
                        curr_px = 6
                    else
                        curr_px = 1
                    end
                else
                    -- land
                    curr_px = 4
                end
            else
                curr_px = 1
            end
            if i%2 == 0 then
                -- even pixel -> low
                curr_byte = curr_px
            else
                -- odd pixel -> high
                curr_byte += (curr_px << 4)
                -- write to memory
                poke(memidx, curr_byte)
                memidx += 1
            end
        end
    end

    printh(#self.objectives)

    self.spawn = vec(208, 108)

    -- initialize player
    self.player:init(self.spawn)

    -- initialize objective
    self:pick_new_objective()

    self.state = "waiting"
end


function game_scene:update()
    if self.state == "waiting" then
        if btnp(4) then
            self.state = "playing"
        end
    elseif self.state == "playing" then
        -- if not self.released_4 then
        --     if not btn(4) then
        --         self.released_4 = true
        --     end
        -- end

        if self.day_timer > 0 then
            self.day_timer -= 1
        else
            sfx(14)
            self.state = "ending"
            self.player:stop()
            self.end_timer = self.END_DURATION
        end

        -- if self.released_4 and btn(4) then
        if btn(4) then
            -- show map
            self.show_map = true
        else
            self.show_map = false
        end

        self.player:update()

        if self.player:is_sunk() then
            self:end_day(true)
        end

        -- check objective
        local curr_pier = self.player:get_pier()

        if curr_pier == self.curr_objective then
            -- got to objective
            if self.player.carrying then
                local pay_level = self:stop_timer()
                self.player:drop(pay_level)
            else
                self.player:pickup()
                self:start_timer()
            end
            self:pick_new_objective()
        end
    elseif self.state == "ending" then
        self.show_map = false
        self.player:update()

        if self.end_timer > 0 then
            self.end_timer -= 1
        else
            self:end_day()
        end
    end

    for particle in all(self.particles_bg) do
        particle:update()
    end
    for particle in all(self.particles_fg) do
        particle:update()
    end

    -- follow player
    local cam_target = vadd(vmul(self.player.vel, 10), self.player.pos)
    self.cam_pos = get_closest_wrapped(cam_target, self.cam_pos, 128*8, 64*8)
    if self.player:is_hit() then
        self.cam_pos = vlerp(self.cam_pos, cam_target, .5)
    else
        self.cam_pos = cam_target
    end

    self.meter = lerp(self.meter, self.player.gear, .4)

    -- self.cam_pos = vlerp(self.cam_pos, vadd(vmul(self.player.vel, 10), self.player.pos), .2)
end

function game_scene:draw()
    cls(1)
    camera(self.cam_pos.x-64, self.cam_pos.y-64)

    -- background particles
    for particle in all(self.particles_bg) do
        particle:draw()
    end

    -- wrapped map
    for pos in all(get_wrapped_positions(vec(), 128*8, 64*8)) do
        map(0, 0, pos.x, pos.y, 128, 64, 1)
        -- rrect(0, 0, 128*8, 64*8, 0, 8)
    end

    -- show current objective
    for obj in all(get_wrapped_positions(self.curr_objective, 128*8, 64*8)) do
        local obj_x, obj_y = vec_to_coords(obj)
        if self.player.carrying then
            circ(obj_x, obj_y, 10, 11)
        else
            rrect(obj_x-5, obj_y-5, 10, 10, 0, 11)
            -- circfill(obj_x, obj_y, 2, 7)
            spr(self.CRATE_SPRITE,obj_x-4, obj_y-4)
        end
        spr(self.ARROW_SPRITE, obj_x-3, obj_y-10+4*sin(t()))
    end

    -- show current pier
    local curr_pier = self.player:get_pier()
    if curr_pier then
        rrect(curr_pier.x-6, curr_pier.y-6, 12, 12, 0, 7)
    end

    self.player:draw()

    -- DEBUG: line to current objective
    -- local wrapped_objective = get_closest_wrapped(self.player.pos, self.curr_objective, 128*8, 64*8)
    -- line(self.player.pos.x, self.player.pos.y, wrapped_objective.x, wrapped_objective.y, 7)

    -- foreground particles
    for particle in all(self.particles_fg) do
        particle:draw()
    end

    -- ui
    camera()
    print("day "..DAY, 2, 3, 7)

    -- day timer
    line(0, 0, 127, 0, 13)
    line(0, 0, 127*(self.day_timer/self.DAY_DURATION), 0, 7)

    -- gears
    local meter_height = 14*self.meter/(#self.player.GEARS-2)
    -- rrectfill(120, 120-meter_height, 3, meter_height, 0, 7)
    local labels = {"r", "n", "1", "2"}
    rrectfill(112, 117, 20, 7, 2, 0)
    print("●", 112, 118, 7)
    for i=1, #self.player.GEARS do
        -- rrectfill(121, 121-12*i/(#self.player.GEARS-2), 4, 4, 0, 5)
        print(labels[i], 121, meter_height+118-14*i/(#self.player.GEARS-2), self.player.gear == i and 7 or 13)
    end

    -- health
    local x_pos = 63-self.player.health*3
    for i=0, self.player.health-1 do
        print("♥", x_pos+6*i, 3, 7)
        -- circfill(98+i*6, 110, 2, 8)
    end

    -- money
    local x_pos = 127-(1+#tostr(self.pay))*4
    print(self.pay.."$", x_pos, 3, 7)

    -- carrying indicator
    if self.player.carrying then
        rrectfill(1, 109, 10, 10, 0, 7)
        spr(self.CRATE_SPRITE, 2, 110)
    end

    -- timer
    -- if self.player.carrying then
    --     local timer_length = max(100*(1-(t() - self.timer_start)/self.curr_time_goal), 0)
    --     rrectfill(10, 126, timer_length, 2, 7)
    -- end

    -- map
    if self.show_map then
        self:draw_world_map(vec(0, 16))
    end

    -- overlay
    if self.state == "waiting" then
        rrectfill(0, 80, 128, 9, 0, 0)
        print("press 🅾️ to open the map", 8, 82, 7)
    end
end


function game_scene:pick_new_objective()
    local candidates = {}
    for value in all(self.objectives) do
        if value != self.curr_objective and value != self.player:get_pier() then
            add(candidates, value)
        end
    end
    if self.player.carrying then
        self.curr_time_goal = 30
    end
    self.curr_objective = rnd(candidates)
end


function game_scene:start_timer()
    self.timer_start = t()
end


function game_scene:stop_timer()
    local time = t() - self.timer_start
    local ratio = time/self.curr_time_goal
    local level
    if ratio >= 1 then
        level = 1
    elseif ratio >= .75 then
        level = 2
    elseif ratio >= .5 then
        level = 3
    else
        level = 4
    end
    self.pay += self.PAY_RATES[level]
    return level
end


function game_scene:draw_world_map(pos)
    memcpy(0, 0x8000, 0x2000)
    -- background
    rrectfill(pos.x, pos.y, 128, 98, 0, 0)
    rrectfill(pos.x, pos.y+2, 128, 76, 0, 15)
    fillp(0x5a5a.8)
    rrectfill(pos.x, pos.y+6, 128, 68, 0, 1)
    fillp()
    sspr(0, 0, 128, 64, pos.x, pos.y+8)
    -- show current objective
    local obj_pos = vadd(pos, vmul(vsub(self.curr_objective, vec(4, 4)), 1/8))
    circ(obj_pos.x, obj_pos.y+8, 2, 11)
    print("★", obj_pos.x+4, obj_pos.y+6, 7)

    -- if player is next to a pier, show its position
    local curr_pier = self.player:get_pier()
    if curr_pier then
        local pier_pos = vadd(pos, vmul(vsub(curr_pier, vec(4, 4)), 1/8))
        circ(pier_pos.x, pier_pos.y+8, 2, 8)
        print("😐", pier_pos.x+4, pier_pos.y+6, 7)
    end

    -- legend
    print("★:destination", pos.x+1, pos.y+82, 7)
    if curr_pier then
        print("😐:current pier", pos.x+1, pos.y+89, 7)
    else
        print("check position at a pier", pos.x+1, pos.y+89, 5)
    end

    -- reload spritesheet
    reload(0, 0, 0x2000)
end


function game_scene:end_day(sunk)
    local lost_cargo = self.player.carrying and sunk
    evening_scene:enter(self.pay, sunk, lost_cargo)
end
