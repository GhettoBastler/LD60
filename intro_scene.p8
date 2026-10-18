intro_scene = Scene:extend()


intro_scene.TEXT = {
    "welcome to eagle-owl delivery!",
    "the job is simple:\n  1. you pickup a crate\n  2. you deliver the crate\n\neasy, right ?",
    "be quick and you'll even get a\nbonus!",
    "but don't go crazy with the\npaddle steamer: you crash it,\nyou pay!",
    "remember to check your map\nwith 🅾️. it will show you where\nto go next.",
    "what's that ?\n\"does it show me where i am ?\"\nwell, no. that's not how a map\nworks.",
    "if you're really lost,\ni guess you could go to a pier.\nthey'll tell you where you are.",
    "now scram,\ni don't have all day!"
}


intro_scene.TEXT_SPEED = 1
intro_scene.BLINK_DURATION = 10
intro_scene.BOB_DURATION = 4
intro_scene.BOB_HEIGHT = 2


function intro_scene:init()
    self.text_idx = 1
    self.char_timer = 0
    self.char_idx = 0
    self.blink_timer = 0
    self.blinking = false
    self.bob_timer = 0
    self.head_offset = 0
end


function intro_scene:update()
    if self.blinking then
        if self.blink_timer > 0 then
            self.blink_timer -= 1
        else
            self.blinking = false
            self.blink_timer = rnd(60*5)
        end
    else
        if self.blink_timer > 0 then
            self.blink_timer -= 1
        else
            self.blinking = true
            self.blink_timer = self.BLINK_DURATION
        end
    end

    local curr_text = self.TEXT[self.text_idx]
    if self.char_idx < #curr_text then
        if btnp(4) then
            self.char_idx = #curr_text
        else
            if self.char_timer > 0 then
                self.char_timer -= 1
            elseif self.char_idx < #self.TEXT[self.text_idx] then
                self.char_idx += 1
                self.char_timer = self.TEXT_SPEED
                if self.bob_timer > 0 then
                    self.bob_timer -= 1
                else
                    if rnd() <= .3 then
                        sfx(18)
                        self.bob_timer = self.BOB_DURATION
                        self.head_offset = self.BOB_HEIGHT
                    end
                end
            end
        end
    else
        if btnp(4) then
            if self.text_idx < #self.TEXT then
                self.text_idx += 1
                self.char_idx = 0
            else
                transitions.circle_out(vec(64, 64), 60)
                game_scene:enter()
            end
        end
    end

    self.head_offset = lerp(self.head_offset, 0, .2)
end


function intro_scene:draw()
    cls()
    clip(4, 4, 120, 110)
    -- background
    for i=0, 16 do
        for j=0, 16 do
            spr(52, i*8, j*8)
        end
    end
    ovalfill(21, 39, 87, 129, 1)
    ovalfill(32, 30+self.head_offset, 80, 129, 1)
    ovalfill(31, 39, 97, 129, 7)
    ovalfill(32, 40, 96, 128, 2)
    spr(69,48,32+self.head_offset,4,4)
    -- blink
    if self.blinking then
        sspr(72,32,22,5,53,39+self.head_offset)
    end
    -- mouth
    if self.head_offset > 1 then
        sspr(72,37,11,4,60,52+self.head_offset)
    end
    clip()

    -- speech
    rrectfill(0, 78, 128, 40, 0, 7)
    local text = sub(self.TEXT[self.text_idx], 0, self.char_idx)
    print(text, 2, 84, 0)
    if t() % 1 > .5 then
        print("🅾️", 120, 112, 1)
    end
end
