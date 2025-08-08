local AreaData = {
    ["Reverant Hollow"] = {
        Name = "Reverant Hollow",
        Description = "The place from which all echo came and to which all echo will return...",
        Lighting = {
            Brightness = 1,
            ColorShift_Bottom = Color3.new(0, 0, 0),
            ColorShift_Top = Color3.new(0.843137, 0.745098, 0.529412),
            EnvironmentDiffuseScale = 1,
            EnvironmentSpecularScale = 1,
            ExposureCompensation = 0,
            FogColor = Color3.new(0, 0, 0),
            FogEnd = 250,
            FogStart = 0,
            GeographicLatitude = 0,
            GlobalShadows = true,
            OutdoorAmbient = Color3.new(0, 0, 0),
            ShadowSoftness = 0,
            Atmosphere = game.ReplicatedStorage:WaitForChild("Atmospheres"):WaitForChild("DeathArea")
        },
        AreaMusic = game.SoundService:FindFirstChild("AreaMusic") and game.SoundService.AreaMusic:FindFirstChild('Echoes of Serenity')
    }
}

return AreaData 