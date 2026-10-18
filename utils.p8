function approach(value, target, amount)
    if value < target then
        return min(value + amount, target)
    else
        return max(value - amount, target)
    end
end


function symrnd(maxval)
    return rnd(2*maxval) - maxval
end


-- Vector
function vec(x, y)
    return {x=x or 0, y=y or 0}
end


function vec_to_coords(vec)
    return vec.x, vec.y
end


function vsmag(v)
    return v.x^2 + v.y^2
end


function vnorm(v)
    local sm = vsmag(v)
    if sm > 0 then
        return vmul(v, 1/sqrt(sm))
    else
        return vec()
    end
end


function vmul(v, m)
    return vec(v.x*m, v.y*m)
end


function vadd(v1, v2)
    return vec(v1.x+v2.x, v1.y+v2.y)
end


function vsub(v1, v2)
    return vec(v1.x-v2.x, v1.y-v2.y)
end


function vrot(v, a)
    return vec(v.x * cos(a) - v.y * sin(a), v.x * sin(a) + v.y * cos(a))
end


function vcpy(v)
    return vec(v.x, v.y)
end


function lerp(value, target, ratio, threshold)
    if abs(value - target) <= (threshold or 0.01) then
        return target
    else
        return value + (target - value) * ratio
    end
end


function vlerp(value, target, ratio)
    return vec(lerp(value.x, target.x, ratio), lerp(value.y, target.y, ratio))
end


function taxicab(vec)
    return abs(vec.x)+abs(vec.y)
end


function dotprod(v1, v2)
    return v1.x*v2.x + v1.y*v2.y
end


function point_line_distance(point, line_a, line_b)
    -- calculate orthogonal projection
    local vs = vsub(line_b, line_a)
    local t = dotprod(vsub(point, line_a), vs)/dotprod(vs, vs)
    if t >= 0 and t <= 1 then
        -- projection is on the line
        -- calculate height
        local vp = vadd(line_a, vmul(vs, t))
        return sqrt(vsmag(vsub(point, vp)))
    end
end


function cprint(txt, x, y, c, big)
    local x_offset
    if big then
        txt = "\^w\^t"..txt
        x_offset = 64 - 4*(#tostr(txt)-4)
    else
        x_offset = 64 - 2*#tostr(txt)
    end
    print(txt, x_offset + x, y, c)
end


function save_palettes(address)
    -- save current draw and screen palettes in memory
    memcpy(address or 0x8000, 0x5f00, 0x1f)
end


function restore_palettes(address)
    -- restore draw and screen palettes from memory
    memcpy(0x5f00, address or 0x8000, 0x1f)
end


function round(x)
    return flr(x+.5)
end


function draw_polygon(points, pos, col, angle, scale)
    color(col)
    line()
    local curr_pt
    local scale = scale or 1
    for point in all(points) do
        line(vec_to_coords(vadd(pos, vrot(vmul(point, scale), angle))))
    end
    line(vec_to_coords(vadd(pos, vrot(vmul(points[1], scale), angle))))
    line()
end


function get_closest_wrapped(source, target, w, h)
    local best_target = vcpy(target)
    local best_dist = taxicab(vsub(target, source))

    for x_offset=-w, w, w do
        for y_offset=-h, h, h do
            local curr_target = vadd(target, vec(x_offset, y_offset))
            local curr_dist = taxicab(vsub(curr_target, source))
            if curr_dist < best_dist then
                best_target = curr_target
                best_dist = curr_dist
            end
        end
    end
    return best_target
end


function get_wrapped_positions(pos, offset_x, offset_y)
    local res = {}
    local wrap_offsets = {
        vec(0, 0),
        vec(-offset_x, 0),
        vec(offset_x, 0),
        vec(0, -offset_y),
        vec(0, offset_y),
        vec(-offset_x, -offset_y),
        vec(offset_x, -offset_y),
        vec(-offset_x, offset_y),
        vec(offset_x, offset_y),
    }
    for offset in all(wrap_offsets) do
        add(res, vadd(pos, offset))
    end
    return res
end


-- by freds72 (https://www.lexaloffle.com/bbs/?uid=25532)
function rspr(sx,sy,x,y,a,w,cc)
    local clear_col=cc or 0
    local ca,sa=cos(a),sin(a)
    local srcx,srcy,addr,pixel_pair
    local ddx0,ddy0=ca,sa
    local mask=shl(0xfff8,(w-1))
    w*=4
    ca*=w-0.5
    sa*=w-0.5
    local dx0,dy0=sa-ca+w,-ca-sa+w
    w=2*w-1
    for ix=0,w do
        srcx,srcy=dx0,dy0
        for iy=0,w do
            if band(bor(srcx,srcy),mask)==0 then
                local c=sget(sx+srcx,sy+srcy)
                sset(x+ix,y+iy,c)
            else
                sset(x+ix,y+iy,clear_col)
            end
            srcx-=ddy0
            srcy+=ddx0
        end
        dx0+=ddx0
        dy0+=ddy0
    end
end
