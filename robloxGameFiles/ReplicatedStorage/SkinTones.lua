local SkinTones = {}

SkinTones.RACES = {
    Auralin = { -- Warm beige (balanced and natural)
        Color3.fromRGB(250, 225, 200),
        Color3.fromRGB(235, 205, 170),
        Color3.fromRGB(220, 190, 150)
    },
    Veyren = { -- Pale ivory with cool undertones (pale nomads)
        Color3.fromRGB(230, 230, 255),
        Color3.fromRGB(210, 210, 240),
        Color3.fromRGB(190, 190, 225)
    },
    Thalari = { -- Soft sea green (coastal folk)
        Color3.fromRGB(200, 245, 220),
        Color3.fromRGB(170, 225, 195),
        Color3.fromRGB(140, 205, 175)
    },
    Soryn = { -- Cool muted gray-blue (shadowed)
        Color3.fromRGB(180, 180, 210),
        Color3.fromRGB(150, 150, 190),
        Color3.fromRGB(120, 120, 170)
    },
    Drazel = { -- Deep earthy brown-red (mountain people)
        Color3.fromRGB(185, 120, 100),
        Color3.fromRGB(160, 100, 80),
        Color3.fromRGB(135, 80, 60)
    },
    Korrin = { -- Ashen bronze (scarred warriors)
        Color3.fromRGB(210, 170, 120),
        Color3.fromRGB(190, 150, 100),
        Color3.fromRGB(170, 130, 80)
    },
    Elvarei = { -- Soft teal-green (forest dwellers)
        Color3.fromRGB(190, 240, 210),
        Color3.fromRGB(160, 220, 180),
        Color3.fromRGB(130, 200, 150)
    },
    Myrr = { -- Dusty lavender (desert mystics)
        Color3.fromRGB(225, 200, 225),
        Color3.fromRGB(205, 180, 205),
        Color3.fromRGB(185, 160, 185)
    },
    Heshari = { -- Pale silver-white (spectral beings)
        Color3.fromRGB(240, 240, 240),
        Color3.fromRGB(210, 210, 210),
        Color3.fromRGB(180, 180, 180)
    },
    Tollin = { -- Warm ochre (underground crafters)
        Color3.fromRGB(240, 220, 170),
        Color3.fromRGB(215, 195, 140),
        Color3.fromRGB(190, 170, 110)
    }
}



SkinTones.HAIR_COLORS = {
    Auralin = Color3.fromRGB(120, 85, 60),     -- Soft brown to match warm beige skin
    Veyren = Color3.fromRGB(220, 220, 240),    -- Silvery white, pale with cool tint
    Thalari = Color3.fromRGB(60, 90, 75),      -- Deep sea green to match coastal tones
    Soryn = Color3.fromRGB(90, 90, 110),       -- Muted dark gray-blue
    Drazel = Color3.fromRGB(80, 50, 40),       -- Deep auburn-brown, earthy like skin
    Korrin = Color3.fromRGB(100, 60, 30),      -- Charred bronze, darker than skin
    Elvarei = Color3.fromRGB(70, 100, 70),     -- Forest green-brown blend
    Myrr = Color3.fromRGB(160, 120, 160),      -- Dusty purple, subdued and mystic
    Heshari = Color3.fromRGB(220, 220, 220),   -- Pale gray-white, ghostlike
    Tollin = Color3.fromRGB(90, 70, 40)        -- Warm clay-brown, earthy
}


function SkinTones.GetRandomSkinTone(race)
    local raceTones = SkinTones.RACES[race]
    if not raceTones then
        return Color3.fromRGB(200, 200, 200)
    end
    return raceTones[math.random(1, #raceTones)]
end

function SkinTones.GetSkinToneByIndex(race, index)
    local raceTones = SkinTones.RACES[race]
    if not raceTones then
        return Color3.fromRGB(200, 200, 200)
    end
    index = math.clamp(index, 1, #raceTones)
    return raceTones[index]
end

function SkinTones.GetHairColor(race)
    return SkinTones.HAIR_COLORS[race] or Color3.fromRGB(101, 67, 33)
end

return SkinTones 