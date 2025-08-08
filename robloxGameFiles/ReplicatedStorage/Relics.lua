local Relics = {}

Relics.EchoRelics = {
    { Name = "Faded Whisper Stone", Weight = 20 },
    { Name = "Tarnished Resonant Ring", Weight = 18 },
    { Name = "Cracked Echo Shard", Weight = 22 },
    { Name = "Ancient Hum Talisman", Weight = 15 },
    { Name = "Lost Harmonic Pendant", Weight = 10 },
    { Name = "Fractured Lullaby Idol", Weight = 5 },
    { Name = "Silent Choir Charm", Weight = 8 },
    { Name = "Hollow Chime Fragment", Weight = 12 },
    { Name = "Veiled Echo Rune", Weight = 7 },
    { Name = "Lingering Note Scroll", Weight = 3 }
}

function Relics.GetRandomRelic()
    local totalWeight = 0
    for _, relic in ipairs(Relics.EchoRelics) do
        totalWeight = totalWeight + relic.Weight
    end
    
    local random = math.random(1, totalWeight)
    local currentWeight = 0
    
    for _, relic in ipairs(Relics.EchoRelics) do
        currentWeight = currentWeight + relic.Weight
        if random <= currentWeight then
            return relic
        end
    end
    
    return Relics.EchoRelics[1]
end

return Relics 