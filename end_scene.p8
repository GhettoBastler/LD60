end_scene = Scene:extend()


end_scene.TEXTS = {
    {   0,
        "listen, i'm sure you have many\ntalents. but deliveries ain't\none of them...",
    },
    {   10,
        "not bad! keep up the good work!",
    },
    {   50,
        "poseidon almighty! great job!",
    },
}


function end_scene:init()
    self.text = self.TEXTS[1][2]

    for idx=#self.TEXTS, 1, -1 do
        local threshold, text = unpack(self.TEXTS[idx])
        if MONEY >= threshold then
            self.text = text
            break
        end
    end
end


function end_scene:update()
    if btnp(4) then
        MONEY = 0
        DAY = 1
        title_scene:enter()
    end
end


function end_scene:draw()
    cls(1)
    cprint("game over", 0, 8, 7, true)
    cprint("total: "..MONEY.."$", 0, 32, 7)
    print(self.text, 4, 48, 7)

    cprint("thank you for playing!", 0, 100, 7)
    if t() % 1 < .5 then
        cprint("press 🅾️ to restart", -3, 110, 10)
    end
end
