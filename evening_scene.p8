evening_scene = Scene:extend()

evening_scene.LOST_FEE = 100
evening_scene.TOW_FEE = 50
evening_scene.BOAT_FEE = 10

evening_scene.TEXT = {
    "",
    "we have recieved reports of\nicebergs in the area. please\nproceed with caution.\n\na new map with the locations \nof said icebergs will be\nsent to you tomorrow.",
    "please find attached the new\nversion of the map, updated\nwith the location of the\nicebergs.",
    "",
    "massive ice formations\nblocking the waterways.\nplease plan your deliveries\naccordingly.\na new map will be sent to you\nshortly.",
    "please find attached the new\nversion of the map, updated\nwith the location of the ice\nformations.",
}

function evening_scene:init(pay, sunk, lost_cargo)
    self.pay = pay
    self.sunk = sunk
    self.lost_cargo = lost_cargo
    self.savings = MONEY
    MONEY += pay
    if sunk then
        MONEY -= self.TOW_FEE
    end
    if lost_cargo then
        MONEY -= self.LOST_FEE
    end
    MONEY -= self.BOAT_FEE
    self.bulletin = self.TEXT[DAY]
    self.bulletin_open = false
end


function evening_scene:update()
    if self.bulletin and #self.bulletin > 0 then
        if self.bulletin_open then
            if btnp(4) then
                if DAY < TOTAL_DAYS then
                    -- go to next day
                    DAY += 1
                    game_scene:enter()
                else
                    -- go to end game
                    end_scene:enter()
                end
            elseif btnp(5) then
                self.bulletin_open = false
            end
        else
            if btnp(4) then
                self.bulletin_open = true
            end
        end
    else
        if btnp(4) then
            if DAY < TOTAL_DAYS then
                -- go to next day
                DAY += 1
                game_scene:enter()
            else
                -- go to end game
                end_scene:enter()
            end
        end
    end
end


function evening_scene:draw()
    cls(1)
    cprint("end of day "..DAY, 0, 4, 7, true)
    print("pay: "..self.pay.."$", 4, 32, 11)
    print("ship rental fee: -"..self.BOAT_FEE.."$", 8)
    if self.sunk then
        print("towing fee: -"..self.TOW_FEE.."$", 8)
    end
    if self.lost_cargo then
        print("lost cargo: -"..self.LOST_FEE.."$", 8)
    end
    print("savings: "..self.savings.."$", 7)
    print("\ntotal: "..MONEY.."$", 7)
    local y_pos = @0x5f27 - 10
    line(2, y_pos, 80, y_pos, 7)

    if self.bulletin and #self.bulletin > 0 then
        if self.bulletin_open then
                rrectfill(1, 3, 126, 122, 0, 7)
                cprint("e.o.d. memo", 0, 8, 1)
                line(32, 16, 96, 16, 0)
                print("dearest employee,\n\n"..self.bulletin.."\n\n\fdour sincerest regards,\n\n\nh. meers,\nchief of deliveries", 4, 28, 0)
                if t() % 1 < .5 then
                    print("🅾️: next day        ❎: return", 4, 118, 1)
                end
        else
            cprint("new memo recieved!", 0, 80, 10)
            if t() % 1 < .5 then
                cprint("press 🅾️ to open", -3, 88, 10)
            end
        end
    else
        if t() % 1 < .5 then
            cprint("press 🅾️ to continue", -3, 88, 10)
        end
    end
end
