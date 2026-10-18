transitions = {}

function transitions.circle_in(center, duration)
    local step = 1/duration
    local radius
    for i=1, duration do
        radius = 182*(i*step)^3
        if radius < 0.5 then
            camera()
            rectfill(0, 0, 128, 128, 0)
        else
            _draw()
            circfill(center.x, center.y, radius, 0x1800)
            flip()
        end
    end
end

function transitions.circle_out(center, duration)
    -- camera() -- reset camera
    for i=1, duration do
        local ratio = (1 - (i / duration))^4
        if ratio < 0.01 then
            -- rectfill(0, 0, 128, 128, 0)
            cls()
        else
            circfill(center.x, center.y, ratio*182, 0x1800)
        end
        flip()
    end
end

function transitions.pan(duration, down)
    -- note: this uses memory adresses 0xc000 to 0xffff, and might glitch if
    -- _draw() writes at these adresses

    -- store current screen in memory
    memcpy(0xc000, 0x6000, 0x2000)
    _draw()
    -- copy new screen to memory
    memcpy(0xe000, 0x6000, 0x2000)

    local step, y, offset = 1/duration
    for i=1, duration do
        local t = 1-i*step
        y = flr(128*(1-(t^3)))
        offset = 0x40 * y
        -- copy saved memory on screen, with offset
        if down then
            -- copy bottom of the current screen and top of the next
            memcpy(0x6000, 0xc000 + offset, 0x2000 - offset) -- curr
            memcpy(0x6000 + 0x2000 - offset, 0xe000, offset) -- new
        else
            -- copy top of the current screen and bottom of the next
            memcpy(0x6000, 0xe000 + 0x2000 - offset, offset) -- new
            memcpy(0x6000 + offset, 0xc000, 0x2000 - offset) -- curr
        end

        flip()
    end
end
