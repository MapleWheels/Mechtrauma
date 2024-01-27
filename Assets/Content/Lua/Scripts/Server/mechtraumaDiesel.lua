MT.DF = {}


--table for dieselEngine models
MT.DE = {
    s5000D={
        maxHorsePower=5000*1.5,
        oilSlots=2,
        oilFilterSlots=1,
        dieselFuelSlots=6,
        auxOxygenSlots=3,
        name="s5000D",
        maxReliability = 90,
        maxEfficiency = 95,
    },
    s3000D={
        maxHorsePower=3000*1.5,
        oilSlots=1,
        oilFilterSlots=1,
        dieselFuelSlots=4,
        auxOxygenSlots=2,
        name="s3000D",
        maxReliability = 90,
        maxEfficiency = 95,
    },
    s3000Da={
        autoStart = false, -- (NI)
        maxHorsePower = 3000, -- engineblock componenent
        coolantCapacity = 8000, -- CL (80L)
        maxOverdive = 1.5,
        engineBlockLocation = 0, -- engineblock componenent
        cylinderHeadLocation = 0, -- engineblock componenent
        crankAssemblyLocation = 1, -- engineblock componenent
        oilSlots = 1,
        oilFilterSlots = 1,
        dieselFuelSlots = 1,
        --heatExchangerLocation=3,
        independentHeatExchanger=true,
        coolantPump = true,
        fuelFilterLocation = 4,
        fuelPumpLocation = 5,
        batteryLocation = 6, -- container slot in XML
        starterMotorLocation = 7,
        dcmLocation = 8,
        exhaustManifoldLocation = 9,
        airFilterLocation = 11,
        auxOxygenSlots= 1,
        name="s3000Da",
        maxReliability = 90, -- should have its own componenet? service? maintenance? deterioration?
        maxEfficiency = 1.0, -- should have its own componenet? service? maintenance? deterioration?
    },
    s3000DGa={
        autoStart = false, -- (NI)
        maxHorsePower = 3000, -- engineblock componenent
        coolantCapacity = 8000, -- CL (80L)
        maxOverdive = 1.5,
        engineBlockLocation = 0, -- engineblock componenent
        cylinderHeadLocation = 0, -- engineblock componenent
        crankAssemblyLocation = 1, -- engineblock componenent
        oilSlots = 1,
        oilFilterSlots = 1,
        dieselFuelSlots = 1,
        --heatExchangerLocation=3,
        independentHeatExchanger=true,
        coolantPump = true,
        fuelFilterLocation = 4,
        fuelPumpLocation = 5,
        batteryLocation = 6, -- container slot in XML
        starterMotorLocation = 7,
        dcmLocation = 8,
        exhaustManifoldLocation = 9,
        airFilterLocation = 11,
        auxOxygenSlots= 1,
        name="s3000Da",
        maxReliability = 90, -- should have its own componenet? service? maintenance? deterioration?
        maxEfficiency = 1.0, -- should have its own componenet? service? maintenance? deterioration?
    },
    sC2500Da={
        maxHorsePower=2500*1.5,
        oilSlots=2,
        oilFilterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=3,
        name="s2500Da",
        maxReliability = 100,
        maxEfficiency = 100,
    },
    sC2500Db={
        maxHorsePower=2500*1.5,
        oilSlots=2,
        oilFilterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=3,
        name="s2500Db",
        maxReliability = 100,
        maxEfficiency = 100,
    },
        sC2500Dc={
        maxHorsePower=2500*1.5,
        oilSlots=2,
        oilFilterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=3,
        name="s2500Dc",
        maxReliability = 100,
        maxEfficiency = 100,
    },
    s1500D={
        maxHorsePower=1500*1.5,
        oilSlots=1,
        oilFilterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=1,
        name="s1500D",
        maxReliability = 100,
        maxEfficiency = 100,
    },
    PDG500={
        maxHorsePower=500*1.5,
        oilSlots=1,
        oilFilterSlots=1,
        dieselFuelSlots=1,
        auxOxygenSlots=1,
        name="PDG500",
        maxReliability = 100,
        maxEfficiency = 100,
    },
    PDG250={
        maxHorsePower=250*1.5,
        oilSlots=1,
        oilFilterSlots=1,
        dieselFuelSlots=1,
        auxOxygenSlots=1,
        name="PDG250",
        maxReliability = 100,
        maxEfficiency = 100,
    }
}

-- -------------------------------------------------------------------------- --
--                            DIESEL SYSTEMS CHECKS                           --
-- -------------------------------------------------------------------------- --

function MT.DF.airFilterCheck(item, dieselSeries, airFilter)
    local airFilterCheck = true -- defaults to true for dieselSeries with no airFilter

    -- did I get wet?
    if item.InWater and airFilter ~= nil then
        airFilter.AddTag("water")
        MT.itemCache[airFilter].counter = 15 -- airFilter will dry out after ~30 seconds
    end

    if dieselSeries.airFilterLocation and item.InWater == false then
        -- airFilter required
        if airFilter == nil then
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1011: NO AIR FILTER*")
            airFilterCheck = false
        elseif airFilter.ConditionPercentage < 1 or airFilter.HasTag("blocked") then
            airFilterCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1012: AIR FILTER BLOCKED*")
        elseif airFilter.HasTag("water") then
            airFilterCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1012: AIR FILTER BLOCKED*")
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1013: AIR FILTER WET*")
        end
    end
    return airFilterCheck
end

-- -------------------------------------------------------------------------- --
--                            COOLING SYSTEM CHECK                            --
-- -------------------------------------------------------------------------- --
-- at 15 PSI antifreeze 50/50 will boil at 257f (125c)


function MT.DF.coolingCheck(item, dieselSeries, DieselEngine, heatExchanger, coolantPump)
    local coolingCheck = true

        -- check if a heat exchanger is required and pressent
        if heatExchanger == nil or heatExchanger.Condition < 1 then
            DieselEngine.CoolingAvailable = 0
            coolingCheck = false
            return
        -- check if a linked heatchanger is required and present
        elseif dieselSeries.ExternalHeatExchanger and DieselEngine.ExternalHeatExchanger == nil then
            DieselEngine.CoolingAvailable = 0
            coolingCheck = false
            return
        -- check if a water pump is required and present
        elseif dieselSeries.coolantPump and coolantPump == nil or coolantPump.condition < 0 then
            DieselEngine.CoolingAvailable = 0
            coolingCheck = false
            return
        else
            -- calculate available cooling
            DieselEngine.CoolingAvailable = (DieselEngine.CoolingCapacity * (heatExchanger.ConditionPercentage / 100) * (coolantPump.ConditionPercentage / 100) * DieselEngine.CoolantLevel)
        end
    return coolingCheck
end

function MT.DF.compressionCheck(item, DieselEngine, engineBlock, cylinderHead, cylinderHeadGasket, crankAssembly)
    local compressionCheck = true -- defaults to true for dieselSeries with no engineBlock
    if DieselEngine.Generation == "3rd" then
        if engineBlock == nil or cylinderHead == nil or crankAssembly == nil then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1018: FAILED COMPRESSION CHECK*")
            compressionCheck = false
        elseif engineBlock.ConditionPercentage < 1 or engineBlock.HasTag("cracked") or cylinderHead.ConditionPercentage < 1 or crankAssembly.ConditionPercentage < 1 then
            compressionCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1018: FAILED COMPRESSION CHECK*")
        end
    end
    if DieselEngine.EngineBlockLocation then
       if not cylinderHeadGasket or cylinderHeadGasket.ConditionPercentage < 1 or cylinderHeadGasket.HasTag("blown") then
        table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1019: REDUCED COMPRESSION*")
       end
    end
    return compressionCheck
end

-- (DTC) P0385 stands for “Crankshaft Position Sensor B Circuit Malfunction.”
function MT.DF.dcmCheck(item, dieselSeries, dcm, oxygenSensor, pressureSensor)
    local dcmCheck = {dcm = true, oxygenSensor = true, pressureSensor = true} -- defualt to true for dieselSeries with no dcm
    if dcm == nil or dcm.ConditionPercentage < 1 then
        dcmCheck.dcm = false
        dcmCheck.oxygenSensor = false
        dcmCheck.pressureSensor = false
    else
        if oxygenSensor == nil or oxygenSensor.ConditionPercentage < 1 then dcmCheck.oxygenSensor = false end
        if pressureSensor == nil or pressureSensor.ConditionPercentage < 1 then dcmCheck.pressureSensor = false end
    end
    return dcmCheck
end

function MT.DF.exhaustCheck(item, dieselSeries, exhaustManifold, exhaustManifoldGasket)
    local exhaustCheck
    -- exhaustCheck - this needs to be moved to after combustion...
    if dieselSeries.exhaustManifoldLocation then
        if exhaustManifold == nil then
            --no exhaustManifold - vent exhaust into hull
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1016: EXHAUST LEAK - LARGE*")
        elseif exhaustManifold.ConditionPercentage < 30 and exhaustManifold.ConditionPercentage > 5 then
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1017: EXHAUST LEAK*")
        elseif exhaustManifold.ConditionPercentage < 5 then
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1016: EXHAUST LEAK - LARGE*")
        else
            -- no leak
        end
        if exhaustManifoldGasket == nil then
            -- no exhaustManifoldGasket
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1017: EXHAUST LEAK*")
        elseif exhaustManifoldGasket.ConditionPercentage < 50 then
            -- exhaustManifoldGasket leak
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1018: EXHAUST LEAK - SMALL*")
        else
            -- no exhaustManifoldGasket leak
        end
    end
    return exhaustCheck
end

function MT.DF.dieselCheck(item, dieselVol, dieselFuelNeededCL)
    local dieselCheck = false
    if dieselVol > dieselFuelNeededCL then
        dieselCheck = true
    else
        table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1060: INSUFFICIENT FUEL*")
    end

    -- clear the results from the previous cycle
    MT.itemCache[item].waterInFuel = false
    MT.itemCache[item].contaminantsInFuel = false
    -- only check the fuel items burned in the previous cycle instead of all possible fuel
    if MT.itemCache[item].fuelBurned then
        for fuel in MT.itemCache[item].fuelBurned do
            -- check the recently burned fuel items to see if there was water in them
            if fuel.HasTag("water") then MT.itemCache[item].waterInFuel = true end
            if fuel.HasTag("contaminants") then MT.itemCache[item].contaminantsInFuel = true end
        end
    end

    return dieselCheck
end

-- (DTC) P228C indicates “Fuel Pressure Regulator 1 Exceeded Control Limits – Pressure Too Low.”
function MT.DF.fuelPressureCheck(item, dieselSeries, fuelFilter, fuelPump)
    local fuelPressureCheck = true
    -- check fuelFilter
    if dieselSeries.fuelFilterLocation then
        if fuelFilter == nil then
            fuelPressureCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1090: LOW FUEL PRESSURE*")
        elseif MT.itemCache[item].fuelFilterBypassed == true then
            -- fuelfilter is bypassed
            fuelPressureCheck = true
        elseif fuelFilter.ConditionPercentage < 1 or fuelFilter.HasTag("blocked") or fuelFilter.HasTag("water") then
            fuelPressureCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1010: LOW FUEL PRESSURE*")
        end
    end
    -- check fuelPump
    if dieselSeries.fuelPumpLocation then
        if fuelPump == nil then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1014: LOW FUEL PRESSURE*")
            fuelPressureCheck = false
        elseif fuelPump.ConditionPercentage < 1 or fuelPump.HasTag("blocked") or fuelPump.HasTag("water") then
            fuelPressureCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1015: LOW FUEL PRESSURE*")
        end
    end
    return fuelPressureCheck
end

function MT.DF.oxygenCheck(item, hullOxygenPercentage, auxOxygenVol, oxygenNeeded)
    local oxygenCheck -- oxygenCheck
    if hullOxygenPercentage > 75 or auxOxygenVol > oxygenNeeded then
        oxygenCheck = true
    else
        table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1050: INSUFFICIENT OXYGEN*")
    end
    return oxygenCheck
end
-- ----------------------------- !voltageCheck! ----------------------------- --
function MT.DF.voltageCheck(item, dieselSeries, battery)
    local voltageCheck = true -- default to true for diesel series without batteries

    -- check battery
    if dieselSeries.batteryLocation then -- do I need a battery?
        if battery and battery.Condition > 9 then
            voltageCheck = true
        elseif battery == nil then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1070: NO BATTERY CONNECTED*") -- no battery should disable the DCM
            voltageCheck = false
        else
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1080: LOW VOLTAGE*")
            voltageCheck = false
        end
    end
    return voltageCheck
end

-- ------------------------------ starterCheck ------------------------------ --
function MT.DF.starterCheck(item, dieselSeries,starterMotor)
    local starterCheck = true -- default to true for diesel series without starters

    -- starterMotorCheck
    if dieselSeries.starterMotorLocation then -- do I need a starterMotor?
        if starterMotor and starterMotor.Condition > 0 then
            starterCheck = true
        elseif not starterMotor then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1016: NO STARTER MOTOR INSTALLED*")
            starterCheck = false
        else
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1017: STARTER MOTOR FAILED*")
            starterCheck = false
        end
    end
    return starterCheck
end

function MT.DF.getFluids(item, DieselEngine, parts, dieselSeries)
    local index = 0
    local fluids = {oilItems = {}, oilVol = 0, frictionReduction = 0, coolantItems={}, coolantVol=0,coolantCapacity=0}
    --DieselEngine.CoolantCapacity = 0
    DieselEngine.CoolantVol = 0
    DieselEngine.CoolantLevel = 0
    DieselEngine.CoolingAvailable = 0

    -- DYNAMIC INVENTORY: contained cooling
    if dieselSeries.heatExchangerLocation and parts.heatExchanger ~= nil then
        while(index < parts.heatExchanger.OwnInventory.Capacity) do
            if parts.heatExchanger.OwnInventory.GetItemAt(index) ~= nil then
                local containedItem = parts.heatExchanger.OwnInventory.GetItemAt(index)
                if containedItem.HasTag("coolant") and containedItem.Condition > 0 then
                    table.insert(fluids.coolantItems, containedItem)

                    DieselEngine.CoolantVol = DieselEngine.CoolantVol + containedItem.Condition
                    DieselEngine.CoolantLevel = DieselEngine.CoolantVol / dieselSeries.coolantCapacity
                end
            end
            index = index + 1
            --MT.itemCache[item].coolingSlots = index
        end
    end
    index = 0
    -- DYNAMIC INVENTORY: linkedcooling
    if item.linkedTo ~= nil then
        for k, linkedItem in pairs(item.linkedTo) do
            if linkedItem.HasTag("heatexchanger") then
                DieselEngine.ExternalHeatExchanger = linkedItem
                while(index < linkedItem.OwnInventory.Capacity) do
                    if linkedItem.OwnInventory.GetItemAt(index) ~= nil then
                        local containedItem = linkedItem.OwnInventory.GetItemAt(index)
                        -- get coolant item(s) -
                        if containedItem.HasTag("coolant") and containedItem.Condition > 0 then
                            table.insert(fluids.coolantItems, containedItem)
                            DieselEngine.CoolantVol = DieselEngine.CoolantVol + containedItem.Condition
                            DieselEngine.CoolantLevel = DieselEngine.CoolantVol / dieselSeries.coolantCapacity
                        end
                    end
                    index = index + 1
                end
            end
        end
    end
    index = 0
    -- DYNAMIC INVENTORY: OIL
    while(index < item.OwnInventory.Capacity) do
    if item.OwnInventory.GetItemAt(index) ~= nil then
        local containedItem = item.OwnInventory.GetItemAt(index)
        if containedItem.HasTag("oil") and containedItem.Condition > 0 then
            table.insert(fluids.oilItems, containedItem)
            fluids.oilVol = fluids.oilVol + containedItem.Condition
            -- LUBRICATE: reduce *possible* friction damage for this oil slot
            fluids.frictionReduction = fluids.frictionReduction + (MT.Config.FrictionBaseDPS * MT.Deltatime)
        end
    end
    index = index + 1
    end
    return fluids
end

function MT.DF.getFuels(item, DieselSeries)
    local index = 0
    local fuels = {dieselItems = {}, dieselVol = 0, auxOxygenItems = {}, auxOxygenVol = 0}
    -- DYNAMIC INVENTORY: auxDiesel
    if item.linkedTo ~= nil then
        for k, linkedItem in pairs(item.linkedTo) do
            if linkedItem.HasTag("dieseltank") then
                while(index < linkedItem.OwnInventory.Capacity) do
                    if linkedItem.OwnInventory.GetItemAt(index) ~= nil then
                        local containedItem = linkedItem.OwnInventory.GetItemAt(index)
                        -- get diesel item(s) - need to add support for linked tanks
                        if containedItem.HasTag("diesel_fuel") and containedItem.Condition > 0 then
                            table.insert(fuels.dieselItems, containedItem)
                            fuels.dieselVol = fuels.dieselVol + containedItem.Condition
                        end
                    end
                    index = index + 1
                end
            end
        end
    end

    -- DYNAMIC INVENTORY: local diesel
    index = 0
    while(index < item.OwnInventory.Capacity) do
        if item.OwnInventory.GetItemAt(index) ~= nil then
            local containedItem = item.OwnInventory.GetItemAt(index)
            -- get diesel item(s) - need to add support for linked tanks
            if containedItem.HasTag("diesel_fuel") and containedItem.Condition > 0 then
                table.insert(fuels.dieselItems, containedItem)
                fuels.dieselVol = fuels.dieselVol + containedItem.Condition
            -- get aux oxygen item(s)
            elseif containedItem.HasTag("refillableoxygensource") and containedItem.Condition > 0 then
                table.insert(fuels.auxOxygenItems, containedItem)
                fuels.auxOxygenVol = fuels.auxOxygenVol + containedItem.Condition
            end
        end
    index = index + 1
    end
    return fuels
end

function MT.DF.getTemperatureZone(currentTemp, operatingTemp, desiredOutput)
    local result
    if desiredOutput == nil then desiredOutput = "temp" end
    -- temperature zone
    -- someday dynamically calculate RBG for gradiant
    if desiredOutput == "color" then
        if currentTemp / operatingTemp >= 1.5 then result = Color(255,0,0,255)  -- old 300f
        elseif currentTemp / operatingTemp > 1.3 then result = Color(200,20,10,255) -- 260f
        elseif currentTemp / operatingTemp > 1.2 then result = Color(255,80,40,255) -- old 240f
        elseif currentTemp / operatingTemp > 1.1 then result = Color(255,120,40,255) -- old 220f
        elseif currentTemp / operatingTemp > 0.9 then result = Color(50,255,100,255) -- old 180f
        elseif currentTemp > 0.16 then result = Color(50,200,255,255) -- old 32f
        else result = Color(50,255,150,255)
        end
        return result
    else
        if currentTemp / operatingTemp >= 1.5 then result = "failure"
        elseif currentTemp / operatingTemp > 1.3 then result = "critical"
        elseif currentTemp / operatingTemp > 1.2 then result = "over"
        elseif currentTemp / operatingTemp > 1.1 then result = "high"
        elseif currentTemp / operatingTemp > 0.9 then result = "operating"
        elseif currentTemp / operatingTemp > 0.16 then result = "low"
        else result = "freezing"
        end
        return result
    end
end


-- -------------------------------------------------------------------------- --
--                              PART FALT EVENTS                              --
-- -------------------------------------------------------------------------- --
-- probably needs a refactor


function MT.DF.partFaultEvents(item, DieselEngine, parts, engineReliability) -- get or set part failures?
    -- coolantPump fault events
    -- fuelFilter fault events
    if DieselEngine.Generation ~= "3rd" then return end

        -- airFilter fault events
    if parts.airFilter then
        local extraModifier = 1.0
        if parts.airFilter.HasTag("mold") then extraModifier = 0.5 end -- increase fungus spawn rate
        if MT.DF.partFaultProbability(parts.airFilter, MT.Config.FuelPumpSLD, engineReliability, extraModifier) then -- piggy backing on fuelPump servicelife for the moment
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("spore_fungus"), parts.airFilter.OwnInventory, nil, nil, function(item) end) -- daww, its back!
        end
    end

    if parts.fuelFilter and MT.itemCache[item].fuelFilterBypassed == false then
        -- water contamination from bad fuel
        if MT.itemCache[item].waterInFuel and MT.HF.Probability(1,20) then parts.fuelFilter.AddTag("water") end
        -- water contamiation from being submerged
        if MT.itemCache[item].waterInFuel and MT.HF.Probability(1,100) then parts.fuelFilter.AddTag("water") end
        -- other contamination
        if MT.itemCache[item].contaminantsInFuel and MT.HF.Probability(1,10) then parts.fuelFilter.AddTag("blocked") end --MT.itemCache[item].contaminantsInFuel

        --[[ legacy random blockage calc
        if MT.DF.partFaultProbability(parts.fuelFilter,MT.Config.FuelFilterSLD, engineReliability) then
            parts.fuelFilter.AddTag("blocked") -- add a blockage - in the future make it more likely when diesel tanks are damaged / submerged / contain cheap diesel.
        end]]
    end

    if parts.fuelPump then
    -- fuelPump fault events

        if MT.itemCache[item].fuelFilterBypassed == true then
            -- if the fuelFilter is bypassed, dramatically increase the probability of faults
            if MT.itemCache[item].waterInFuel and MT.HF.Probability(1,4) then parts.fuelPump.AddTag("water") end
            if MT.itemCache[item].contaminantsInFuel and MT.HF.Probability(1,10) then parts.fuelPump.AddTag("blocked") end
        elseif MT.itemCache[item].fuelFilterBypassed == false then
            -- if the fuelFilter isn't bypassed, there is only a small chance water or contaminants get through
            if MT.itemCache[item].waterInFuel and MT.HF.Probability(1,100) then parts.fuelPump.AddTag("water") end
            if MT.itemCache[item].contaminantsInFuel and MT.HF.Probability(1,100) then parts.fuelPump.AddTag("blocked") end
        end
        --[[ legacy random blockage calc
        if MT.DF.partFaultProbability(parts.fuelPump, MT.Config.FuelPumpSLD, engineReliability) then
            local faultEvents = {}-- blocked
            parts.fuelPump.AddTag("blocked") -- in the future make it more likely when diesel tanks are damaged / submerged / contain cheap diesel.
            -- water - but I need to add a weighted random selection
        end ]]
    end

    -- coo
    -- heatExchanger fault events
    --
    -- overheating fault events?
    if parts.engineBlock then
        local thermal = MTUtils.GetComponentByName(parts.engineBlock, "Mechtrauma.Thermal")
        -- cracking
        if thermal.ContractionStress > 0 and MT.HF.Probability(thermal.CumulativeStress, 100000) then
            parts.engineBlock.AddTag("cracked")
        -- warping
        elseif thermal.ExpansionStress > 0 and MT.HF.Probability(thermal.CumulativeStress, 100000) then
            parts.engineBlock.AddTag("warped")
        end
    end
    if parts.cylinderHead then
        local thermal = MTUtils.GetComponentByName(parts.cylinderHead, "Mechtrauma.Thermal")
        -- cracking
        if thermal.ContractionStress > 0 and MT.HF.Probability(thermal.CumulativeStress, 100000) then
            parts.cylinderHead.AddTag("cracked")
        -- warping
        elseif thermal.ExpansionStress > 0 and MT.HF.Probability(thermal.CumulativeStress, 100000) then
            parts.cylinderHead.AddTag("warped")
        end
    end

    if parts.cylinderHeadGasket then
        local thermal = MTUtils.GetComponentByName(parts.cylinderHeadGasket, "Mechtrauma.Thermal")
        -- blown
        -- or if head cracked/warped or block warped
        if thermal.ContractionStress > 0 or thermal.ExpansionStress > 0 and MT.HF.Probability(thermal.CumulativeStress, 10000) then
            parts.cylinderHeadGasket.AddTag("blown")
        end
    end

end

-- calculate the probability of a part fault event
-- this calculation makes the assumption, that, under perfect conditions, the part will experience one fault (on average) once during its serviceLife.
-- this isn't the case as engine reliability and part deterioration increase the probability by decreasing the max probability range
-- extraModifier: this allows for increasing or decreasing the probability at the time of the function call.
function MT.DF.partFaultProbability(part, serviceLife, reliability, extraModifier)
    if extraModifier == nil then extraModifier = 1.0 end
    return MT.HF.Probability(1, MT.HF.Round( serviceLife * reliability * (part.ConditionPercentage / 100) * MT.Config.PartFaultRangeModifier * extraModifier, 0))
end

function MT.DF.getParts(item, DieselEngine, dieselSeries)
    local index = 0
    local parts = {oilFilterItems = {}, oilFilterCount = 0, oilFilterVol = 0}
    parts.oilFiltrationSlots = dieselSeries.oilFilterSlots
    parts.oilFiltrationVol = 0
    parts.frictionParts = {}
    parts.thermalParts = {}

    -- STATIC INVENTORY PARTS: add any staticly located items to the parts inventory
    -- heatExchanger
    if dieselSeries.heatExchangerLocation and item.OwnInventory.GetItemAt(dieselSeries.heatExchangerLocation) ~= nil then parts.heatExchanger = item.OwnInventory.GetItemAt(dieselSeries.heatExchangerLocation) end
    -- fuelFilter (if any)
    if dieselSeries.fuelFilterLocation and item.OwnInventory.GetItemAt(dieselSeries.fuelFilterLocation) ~= nil then
        parts.fuelFilter = item.OwnInventory.GetItemAt(dieselSeries.fuelFilterLocation)
        if parts.fuelFilter.HasTag("rubberhose") then MT.itemCache[item].fuelFilterBypassed = true else MT.itemCache[item].fuelFilterBypassed = false end -- allows bypassing fuelfilter
    end
    -- fuelPump (if any)
    if dieselSeries.fuelPumpLocation and item.OwnInventory.GetItemAt(dieselSeries.fuelPumpLocation) ~= nil then parts.fuelPump = item.OwnInventory.GetItemAt(dieselSeries.fuelPumpLocation) end
    -- airFilter (if any)
    if dieselSeries.airFilterLocation and item.OwnInventory.GetItemAt(dieselSeries.airFilterLocation) ~= nil then parts.airFilter = item.OwnInventory.GetItemAt(dieselSeries.airFilterLocation) end
    -- battery (if any)
    if dieselSeries.batteryLocation and item.OwnInventory.GetItemAt(dieselSeries.batteryLocation) ~= nil then parts.battery = item.OwnInventory.GetItemAt(dieselSeries.batteryLocation) end
    -- starterMotor (if any)
    if dieselSeries.starterMotorLocation and item.OwnInventory.GetItemAt(dieselSeries.starterMotorLocation) ~= nil then parts.starterMotor = item.OwnInventory.GetItemAt(dieselSeries.starterMotorLocation) end
    -- exhaustManifold (if any)
    if dieselSeries.exhaustManifoldLocation and item.OwnInventory.GetItemAt(dieselSeries.exhaustManifoldLocation) ~= nil then
        parts.exhaustManifold = item.OwnInventory.GetItemAt(dieselSeries.exhaustManifoldLocation)
        table.insert(parts.thermalParts, parts.exhaustManifold) end
    -- exhaustManifoldGasket (if any)
    if dieselSeries.exhaustManifoldLocation and parts.exhaustManifold ~= nil and parts.exhaustManifold.OwnInventory.GetItemAt(0) ~= nil then
        parts.exhaustManifoldGasket = parts.exhaustManifold.OwnInventory.GetItemAt(0)
        table.insert(parts.thermalParts, parts.exhaustManifoldGasket) end
    -- dcm (if any)
    if dieselSeries.dcmLocation and item.OwnInventory.GetItemAt(dieselSeries.dcmLocation) ~= nil then
        parts.dcm = item.OwnInventory.GetItemAt(dieselSeries.dcmLocation)
        if parts.dcm.OwnInventory.GetItemAt(2) ~= nil then parts.oxygenSensor = parts.dcm.OwnInventory.GetItemAt(2) end
        if parts.dcm.OwnInventory.GetItemAt(3) ~= nil then parts.pressureSensor = parts.dcm.OwnInventory.GetItemAt(3) end
    end
    -- engineBlock (if any)
    if DieselEngine.EngineBlockLocation and item.OwnInventory.GetItemAt(DieselEngine.EngineBlockLocation) ~= nil then
        parts.engineBlock = item.OwnInventory.GetItemAt(DieselEngine.EngineBlockLocation)
        table.insert(parts.frictionParts, parts.engineBlock) -- add this to the parts list for friction damage
        table.insert(parts.thermalParts, parts.engineBlock)
        parts.engineBlockSpecs = MTUtils.GetComponentByName(parts.engineBlock, "Mechtrauma.EngineBlock")
        if dieselSeries.cylinderHeadLocation and parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.cylinderHeadLocation) then
            parts.cylinderHead = parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.cylinderHeadLocation)
            table.insert(parts.frictionParts, parts.cylinderHead) -- add this to the parts list for friction damage
            table.insert(parts.thermalParts, parts.cylinderHead)
            if parts.cylinderHead.OwnInventory.GetItemAt(0) then
                parts.cylinderHeadGasket = parts.cylinderHead.OwnInventory.GetItemAt(0)
                table.insert(parts.thermalParts, parts.cylinderHeadGasket)
            end
        end
        if dieselSeries.crankAssemblyLocation and parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.crankAssemblyLocation) then
            parts.crankAssembly = parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.crankAssemblyLocation)
            table.insert(parts.frictionParts, parts.crankAssembly) -- add this to the parts list for friction damage
            table.insert(parts.thermalParts, parts.crankAssembly)
        end
    end
    -- external heatExchanger (if any)
    if dieselSeries.independentHeatExchanger then
        -- DYNAMIC INVENTORY: heat exchanger
        index = 0
        if item.linkedTo ~= nil then
            for k, linkedItem in pairs(item.linkedTo) do
                if linkedItem.HasTag("heatexchanger") then
                    DieselEngine.ExternalHeatExchanger = linkedItem
                    while (index < item.OwnInventory.Capacity) do
                        if linkedItem.OwnInventory.GetItemAt(index) ~= nil then
                            local containedItem = linkedItem.OwnInventory.GetItemAt(index)
                            if containedItem.HasTag("heatexchangercore") and containedItem.Condition > 0 then
                                parts.heatExchanger = containedItem
                                table.insert(parts.thermalParts, containedItem)
                            elseif containedItem.HasTag("coolantpump") and containedItem.Condition > 0 then
                                parts.coolantPump = containedItem
                                table.insert(parts.thermalParts, containedItem)
                            end
                        end
                        index = index + 1
                    end
                end
            end
        end
    end

    -- DYNAMIC INVENTORY: loop through the inventory and see what we have
    index = 0
    while(index < item.OwnInventory.Capacity) do
        if item.OwnInventory.GetItemAt(index) ~= nil then
            local containedItem = item.OwnInventory.GetItemAt(index)
            if containedItem.HasTag("oilfilter") and containedItem.Condition > 0 then
                table.insert(parts.oilFilterItems, containedItem)
                parts.oilFilterCount = parts.oilFilterCount + 1
                parts.oilFilterVol = parts.oilFilterVol + containedItem.Condition
            end
        end
        index = index + 1
    end
    return parts
end

function MT.DF.thermalResults(item, thermal, DieselEngine, parts, fluids)
    if DieselEngine.Generation == "3rd" then
        if thermal.Temperature == nil then thermal.Temperature = 60 end -- default temp

        DieselEngine.HeatGenerated = DieselEngine.generatedHP * 120 -- HP:BTU is 1:40 but toal heat output is 3x HP
        DieselEngine.CoolingNeeded = DieselEngine.generatedHP * 40 -- only 1/3 of BTU goes to coolant, 1/3 goes out ehaust and 1/3 goes into HP
        DieselEngine.HeatSurplus = MT.HF.Clamp(DieselEngine.CoolingNeeded - DieselEngine.CoolingAvailable, 0, 1000000)

        -- Calculate engine and part temps
        if DieselEngine.HeatSurplus > 0 then
            DieselEngine.CoolingNeeded = DieselEngine.CoolingNeeded - DieselEngine.CoolingAvailable
            -- overheat
            thermal.Temperature = thermal.Temperature + (thermal.FailTemp - thermal.Temperature) / 10 * MT.HF.Round(DieselEngine.HeatSurplus / DieselEngine.CoolingCapacity, 2)

            -- apply to thermal parts
            for k, part in pairs(parts.thermalParts) do
                local partThermal = MTUtils.GetComponentByName(part, "Mechtrauma.Thermal")
                partThermal.UpdateTemperature(partThermal.Temperature + (partThermal.FailTemp - partThermal.Temperature) / 10 * MT.HF.Round(DieselEngine.HeatSurplus / DieselEngine.CoolingCapacity, 2))
                partThermal.CalcThermalStress()
            end
        else
            -- normal operations
            if thermal.Temperature < 200 then
                -- increase temperature
                thermal.Temperature = MT.HF.Round(thermal.Temperature + (DieselEngine.OperatingTemperature - thermal.Temperature) / 10 + 1, 2)
                -- apply to thermal parts
                for k, part in pairs(parts.thermalParts) do
                    local partThermal = MTUtils.GetComponentByName(part, "Mechtrauma.Thermal")
                    partThermal.UpdateTemperature(MT.HF.Round(partThermal.Temperature + (partThermal.TargetOpTemp - partThermal.Temperature) / 10 + 1, 2))
                    partThermal.CalcThermalStress()
                end
            else
                -- decrease temperature
                thermal.Temperature = MT.HF.Round(thermal.Temperature - ((DieselEngine.OperatingTemperature - thermal.Temperature) / 10 + - 1)*-1, 2)
                -- apply to thermal parts
                for k, part in pairs(parts.thermalParts) do
                    local partThermal  = MTUtils.GetComponentByName(part, "Mechtrauma.Thermal")
                    partThermal.UpdateTemperature(MT.HF.Round(partThermal.Temperature - ((partThermal.TargetOpTemp - partThermal.Temperature) / 10 + - 1)*-1, 2))
                    partThermal.CalcThermalStress()
                end
            end
        end

        -- -------------------------------------------------------------------------- --
        --                             COOLANT TEMPERATURE                            --
        -- -------------------------------------------------------------------------- --
        -- cooltant temperature quickly adjusts to engine temp. Engine temp is the offical coolant temp
        -- this allows us to track the individual temperatures of the coolant while limiting the benefit of hotswapping coolant
        for k, coolant in pairs(fluids.coolantItems) do
            local coolantThermal = MTUtils.GetComponentByName(coolant, "Mechtrauma.Thermal")
            if thermal.Temperature > coolantThermal.Temperature then
                -- increase coolant temp
                coolantThermal.UpdateTemperature(MT.HF.Round(coolantThermal.Temperature + (thermal.Temperature - coolantThermal.Temperature) / 3 + 1, 2))
            else
                -- decrease coolant temp
                coolantThermal.UpdateTemperature(MT.HF.Round(coolantThermal.Temperature - ((thermal.Temperature - coolantThermal.Temperature) / 3 + - 1)*-1, 2))
            end
        end
    end
end

function MT.DF.getMaxHP(item, DieselEngine, parts)
    local maxHP
    if DieselEngine.Generation == "3rd" then
        if parts.engineBlock then maxHP = parts.engineBlockSpecs.RatedHP else maxHP = 0 end
    else
        maxHP = DieselEngine.RatedHP -- if there is no engine block, just stick with whatever the default HP is.
    end
    -- add modifiers for turbocharger, overdrive mode, hyper fuel etc
    return maxHP
end


-- -------------------------------------------------------------------------- --
--                          MY BELOVED DIESEL ENGINE                          --
-- -------------------------------------------------------------------------- --
-- DESIGN NOTES:
-- HP:kW ~ 1:0.75
-- HP:BTU/h 1:2500
-- HP:BTU/m 1:40 ~
-- HP:diesel(l) 1:0.2


-- called by MT.F.dieselGenerator: calculates if and how much power an engine should be producing
function MT.DF.combustion(item, dieselSeries, targetPower)

    local gridCycles = 60
    local simpleGenerator = MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator")
    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    local DieselEngine = MTUtils.GetComponentByName(item, "Mechtrauma.DieselEngine")
    local thermal = MTUtils.GetComponentByName(item, "Mechtrauma.Thermal")
    local dieselEngine = {}

    -- oxygen - TO DO: move to get fuels
    local hullOxygenPercentage = 0
    -- set hullOxygenPercentage to 0 when submerged or outside of a hull.
    if item.InWater == false and item.FindHull() ~= nil then hullOxygenPercentage = item.FindHull().OxygenPercentage else hullOxygenPercentage = 0 end


    -- -------------------------------------------------------------------------- --
    --                             ESTABLISH INVENTORY                            --
    -- -------------------------------------------------------------------------- --
    local parts = MT.DF.getParts(item, DieselEngine, dieselSeries)
    local fluids = MT.DF.getFluids(item, DieselEngine, parts, dieselSeries) -- we need the parts because they may contain fluids
    local fuels = MT.DF.getFuels(item, dieselSeries)
    DieselEngine.MaxHP = MT.DF.getMaxHP(item, DieselEngine, parts)

    -- -------------------------------------------------------------------------- --
    --                         CALCULATE COMBUSTION NEEDS                         --
    -- -------------------------------------------------------------------------- --
    local dieselFuelNeededCL = MT.Config.DieselHorsePowerRatioCL * MT.HF.Clamp(targetPower, 100, DieselEngine.MaxHP) / 3600 * MT.Deltatime -- 100 min hp is idle speed
    local oxygenNeeded = dieselFuelNeededCL * MT.Config.DieselOxygenRatioCL -- this is where we cheat and pretend that 1 condition of oxygen is equal to 1 condition of diesel

    --print(tostring(MTUtils.GetComponentByName(parts.engineBlock, "Mechtrauma.EngineBlock").RatedHP))

    -- damage and reduction
    local frictionDamage = (MT.Config.FrictionBaseDPS * MT.Deltatime * dieselSeries.oilSlots) - fluids.frictionReduction
    -- calculates total possible oil deterioration and then reduces for each viable filter
    local oilDeterioration = MT.HF.Round((MT.Config.OilBaseDPS * MT.Deltatime * dieselSeries.oilSlots) - (MT.Config.OilBaseDPS * MT.Deltatime * MT.Config.OilFiltrationM * parts.oilFilterCount),0)

    -- DIAGNOSTICS
    MT.itemCache[item].diagnosticData = nil -- clear out the old codes
    MT.itemCache[item].diagnosticData ={errorCodes={},warningCodes={},statusCodes={}} -- redefine the item

    -- -------------------------------------------------------------------------- --
    --                          !CHECK IGNITION SYSTEMS!                          --
    -- -------------------------------------------------------------------------- --

    -- if the engine isn't running, reset the ignition and check the ignition systems
    if DieselEngine.IsRunning == false then
        dieselEngine.ignition = false -- switch the ignition off if the engine has stalled/shutdown

        -- CHECK: IGNITION SYSTEMS
        dieselEngine.starterCheck = MT.DF.starterCheck(item, dieselSeries, parts.starterMotor)
        dieselEngine.voltageCheck = MT.DF.voltageCheck(item, dieselSeries, parts.battery)
    end

    -- -------------------------------------------------------------------------- --
    --                        ***** ATTEMPT IGNITION *****                        --
    -- -------------------------------------------------------------------------- --

    -- ignitionCheck -- need to add probability of failure
    if dieselSeries.batteryLocation and dieselSeries.starterMotorLocation and dieselEngine.ignition == false then
        if dieselEngine.voltageCheck and dieselEngine.starterCheck then
            parts.starterMotor.Condition = parts.starterMotor.Condition - 1 -- deteriorate the starterMotor
            parts.battery.Condition = parts.battery.condition - 10 -- drain the battery

            dieselEngine.ignition = true
        else
            dieselEngine.ignition = false
        end
    else
        dieselEngine.ignition = true -- ignition always true if battery and starterMotor are not required
    end

    -- -------------------------------------------------------------------------- --
    --                         !CHECK COMBUSTION SYSTEMS!                         --
    -- -------------------------------------------------------------------------- --

    -- CHECK: FUELS
    dieselEngine.oxygenCheck = MT.DF.oxygenCheck(item, hullOxygenPercentage, fuels.auxOxygenVol, oxygenNeeded)
    dieselEngine.dieselCheck = MT.DF.dieselCheck(item, fuels.dieselVol, dieselFuelNeededCL)

    -- CHECK: FLUIDS
    dieselEngine.coolingCheck = MT.DF.coolingCheck(item, dieselSeries, DieselEngine, parts.heatExchanger, parts.coolantPump)
    -- Oil


    -- CHECK: SYSTEMS
    dieselEngine.airFilterCheck = MT.DF.airFilterCheck(item, dieselSeries, parts.airFilter)
    dieselEngine.compressionCheck = MT.DF.compressionCheck(item, DieselEngine, parts.engineBlock, parts.cylinderHead, parts.cylinderHeadGasket, parts.crankAssembly)
    dieselEngine.dcmCheck = MT.DF.dcmCheck(item, dieselSeries, parts.dcm, parts.oxygenSensor, parts.pressureSensor)
    dieselEngine.exhaustCheck = MT.DF.exhaustCheck(item, dieselSeries, parts.exhaustManifold, parts.exhaustManifoldGasket)
    dieselEngine.fuelPressureCheck = MT.DF.fuelPressureCheck(item, dieselSeries, parts.fuelFilter, parts.fuelPump)

    -- -------------------------------------------------------------------------- --
    --                       ***** ATTEMPT COMBUSTION *****                       --
    -- -------------------------------------------------------------------------- --

    if item.Condition > 0 and
       dieselEngine.ignition and
       dieselEngine.airFilterCheck and
       dieselEngine.dieselCheck and
       dieselEngine.oxygenCheck and
       dieselEngine.fuelPressureCheck and
       dieselEngine.compressionCheck
    then

    -- -------------------------------------------------------------------------- --
    --                       ***** COMBUSTION *****                               --
    -- -------------------------------------------------------------------------- --
    DieselEngine.IsRunning = true
    dieselEngine.combustion = true

    -- ---------------------- COMBUSTION QUALITY GOES HERE ---------------------- --

    -- adjust the targetPower based on the generator accuracy (over or under produce power)
    targetPower = targetPower * MT.HF.Tolerance(simpleGenerator.Accuracy)

    -- calculate efficiency
    simpleGenerator.Efficiency = dieselSeries.maxEfficiency
    if not dieselEngine.dcmCheck.oxygenSensor then simpleGenerator.Efficiency = simpleGenerator.Efficiency - 0.5 end -- need to make this fluctuate
    oxygenNeeded = oxygenNeeded * (1 - simpleGenerator.Efficiency + 1)
    dieselFuelNeededCL = dieselFuelNeededCL * (1 - simpleGenerator.Efficiency + 1)

    -- calculate reliability
    simpleGenerator.Reliability = item.ConditionPercentage / 100

    -- GENERATE POWER:
    DieselEngine.generatedHP = MT.HF.Round(MT.HF.Clamp(targetPower, 0, DieselEngine.MaxHP), 2)
    if parts.battery then parts.battery.Condition = parts.battery.condition + 0.1 end -- charge the battery (if any)

        -- -------------------------------------------------------------------------- --
        --                           TEMPERATURE AND COOLING                          --
        -- -------------------------------------------------------------------------- --
        --  range      |        zone            | effects
        --   60f       | default temperature    |
        -- < 180       | low temperature        | reduced efficiency
        -- > 180 - 220 | operating temperature  |
        -- > 220 - 240 | high temperature       | reduced efficiency
        -- > 240 - 260 | over temperature       | risk engine damage
        -- > 260 - 300 | critical temperatue    | risk engine failure
        -- = 300       | critical failure       | engine destroyed

        -- iron block, diesel fuel,

        -- -------------------------------------------------------------------------- --
        --                           !CHECK COOLING SYSTEMS!                          --
        -- -------------------------------------------------------------------------- --
        -- this is a hack

        --[[
        local thermalTest = MTUtils.GetComponentByName(parts.engineBlock, "Mechtrauma.Thermal")
        local thermalCoolingStress = MT.HF.Round(thermalTest.GetCoolingStress(5, thermalTest.MaxOpTemp), 0)
        print("engineBlock Temp: ", thermalTest.Temperature)
        --print("High Temp: ", thermalTest.GetHighTempOverTime(30, 200))
        --print("Low Temp: ", thermalTest.GetLowTempOverTime(30, 200))
        print("|===== Temp Hist =====|")
        for k,v in pairs(thermalTest.TemperatureHistory) do
            print(k .. " | " .. v)
        end
        print("====== END HIST =====")

        print("Stress Tick: ", thermalCoolingStress)
        MT.Test = MT.HF.Round(MT.Test + thermalCoolingStress)
        if not MT.HF.approxEquals(thermalCoolingStress, 0, 1) then MT.Test2 = MT.Test2 + 1 end
        print("Total Stress lua: " .. MT.Test .. " c# total cooling stress: " .. thermalTest.CoolingStress)
        print("Total Stress events: ", MT.Test2)]]

        --for k, v in pairs (MTUtils.GetComponentByName(parts.engineBlock, "Mechtrauma.Thermal").TemperatureHistory) do
        --  print(k .. " | " .. v)
        --end

        -- TO DO: move to function call

        MT.DF.thermalResults(item, thermal, DieselEngine, parts, fluids)


        -- -------------------------------------------------------------------------- --
        --                       CONSUMPTION AND DETERIORATION:                       --
        -- -------------------------------------------------------------------------- --

        -- burn oxygen
        if hullOxygenPercentage >= 75 then  -- burn hull oxygen when above 75%
            item.FindHull().Oxygen = item.FindHull().Oxygen - (oxygenNeeded * 2250) -- 2250 hull oxygen ~= 1 oxygen condition
        else
            MT.HF.subFromListSeq (oxygenNeeded, fuels.auxOxygenItems) -- burn auxOxygen
        end
        -- burn diesel
        MT.itemCache[item].fuelBurned = MT.HF.subFromListSeq (dieselFuelNeededCL, fuels.dieselItems) -- burn diesel sequentially, improves resource management
        -- deteriorate oil
        MT.HF.subFromListDis(oilDeterioration, fluids.oilItems) -- total oilDeterioration is spread across all oilItems. (being low on oil will make the remaining oil deteriorate faster)
        -- deteriorate oil filter(s)
        MT.HF.subFromListAll((MT.Config.OilFilterDPS * MT.Deltatime), parts.oilFilterItems) -- apply deterioration to each filters independently, they have already reduced oil deterioration
        -- deteriorate others? I guess others
        if dieselSeries.fuelFilterLocation and parts.fuelFilter ~= nil then -- deteriorate fuel filter
            parts.fuelFilter.Condition = parts.fuelFilter.Condition - (MT.Config.FuelFilterDPS * MT.Deltatime) end
        if dieselSeries.fuelPumpLocation and parts.fuelFilter ~= nil then -- deteriorate fuel pump
            parts.fuelPump.Condition = parts.fuelPump.Condition - (MT.Config.FuelPumpDPS * MT.Deltatime) end
        if dieselSeries.engineBlockLocation and parts.engineBlock ~= nil then -- deteriorate engineBlock
            parts.engineBlock.Condition = parts.engineBlock.Condition - (MT.Config.EngineBlockDPS * MT.Deltatime) end
        if dieselSeries.exhaustManifoldLocation and parts.exhaustManifold ~= nil then -- deteriorate exhaustManifold (if any)
            parts.exhaustManifold.Condition = parts.exhaustManifold.Condition - (MT.Config.exhaustManifoldDPS * MT.Deltatime) end
        if dieselSeries.exhaustManifoldLocation and parts.exhaustManifoldGasket ~= nil then -- deteriorate exhaustGasket (if any)
            parts.exhaustManifoldGasket.Condition = parts.exhaustManifoldGasket.Condition - (MT.Config.exhaustManifoldGasketDPS * MT.Deltatime) end

        -- frictionDamage - damages the item in classic generators, damages the engine parts in the advanced generators
        if next(parts.frictionParts) ~= nil then MT.HF.subFromListAll(frictionDamage * 10, parts.frictionParts) else item.Condition = item.Condition - frictionDamage end

        -- calculate part fault events
        MT.DF.partFaultEvents(item, DieselEngine, parts, simpleGenerator.Reliability)

        -- SOUND / LIGHT - dieselEngine sound is controlled by an XML light so it will toggle with the light(s)
        for k, component in pairs(item.Components) do
            if tostring(component) == "Mechtrauma.MTLight" and component.Token == "soundlight" then component.IsOn = true end
        end

        -- calculate consumables time remaining
        dieselEngine.fuelTime = MT.HF.Round((fuels.dieselVol / dieselFuelNeededCL) * MT.Deltatime / 60, 1)
        dieselEngine.oilTime = MT.HF.Round((fluids.oilVol / oilDeterioration) * MT.Deltatime / 60, 1)
        dieselEngine.filterTime = MT.HF.Round((parts.oilFilterVol / MT.Config.OilFilterDPS) / 60, 1) -- no need to calculate the deltaTime here since calc is already in dps
        dieselEngine.oxygenTime = MT.HF.Round((fuels.auxOxygenVol / oxygenNeeded) * MT.Deltatime / 60, 1)

    else
    -- -------------------------------------------------------------------------- --
    --                        ***** COMBUSTION FAILED *****                       --
    -- -------------------------------------------------------------------------- --

        -- shutdown procedure
        dieselEngine.combustion = false
        DieselEngine.IsRunning = false -- shut it down
        DieselEngine.generatedHP = 0
        simpleGenerator.IsOn = false -- switch off to prevent battery drain (later reimplement autoStart )
        dieselEngine.ignition = false -- reset ignition

        -- SOUND / LIGHT - dieselEngine sound is controlled by an XML light so it will toggle with the light(s)
        for k, component in pairs(item.Components) do
            if tostring(component) == "Mechtrauma.MTLight" and component.Name=="soundlight" then component.IsOn = false end
        end
    end
    -- these to functions
    -- -------------------------------------------------------------------------- --
    --                             ***** STATUS *****                             --
    -- -------------------------------------------------------------------------- --

    if terminal and DieselEngine.ShowStatus and parts.dcm ~= nil and parts.dcm.ConditionPercentage > 1 then
        terminal.ClearHistory()
        -- SHOW: Status - only display if there is a terminal, ignition is implicit
        if dieselEngine.combustion == true then
            terminal.SendMessage("*COMBUSTION: " .. MT.HF.Round(DieselEngine.generatedHP, 0) .. "kW GENERATED*", Color(255,100,50,255))
            terminal.SendMessage("Temperature: " .. MT.HF.Round(thermal.Temperature, 0) .. "F", MT.DF.getTemperatureZone(thermal.Temperature, DieselEngine.OperatingTemperature, "color"))
            terminal.SendMessage(string.format("%-6s", dieselEngine.fuelTime .. "m") .. " of Diesel Fuel remaining", Color.Gray)
            terminal.SendMessage(string.format("%-6s", dieselEngine.oilTime .. "m") .. " of Oil remaining.", Color.Gray)
            terminal.SendMessage(string.format("%-6s", dieselEngine.filterTime .. "m") .. " of Oil Filtration remaining.", Color.Gray)
            terminal.SendMessage(string.format("%-6s", dieselEngine.oxygenTime .. "m") .. " of Oxygen remaining.",Color.Gray)
        end
    end

    -- -------------------------------------------------------------------------- --
    --                              ***** TEMPS *****                             --
    -- -------------------------------------------------------------------------- --
    if terminal and DieselEngine.ShowTemps and parts.dcm ~= nil and parts.dcm.ConditionPercentage > 1 then
        terminal.ClearHistory()
        -- SHOW: Temps - only display if there is a terminal, ignition is implicit
        if dieselEngine.combustion == true then
            terminal.SendMessage("*COMBUSTION: " .. MT.HF.Round(DieselEngine.generatedHP, 0) .. "kW GENERATED*", Color(255,100,50,255))
            terminal.SendMessage("Temperature: " .. MT.HF.Round(thermal.Temperature, 0) .. "F", MT.DF.getTemperatureZone(thermal.Temperature, DieselEngine.OperatingTemperature, "color"))
            for _, part in pairs(parts.thermalParts) do
                local partThermal = MTUtils.GetComponentByName(part, "Mechtrauma.Thermal")
                terminal.SendMessage(part.name .. " - " .. MT.HF.Round(partThermal.Temperature, 0) .. "F", MT.DF.getTemperatureZone(partThermal.Temperature, partThermal.TargetOpTemp, "color"))
            end
        end
    end

    -- -------------------------------------------------------------------------- --
    --                             ***** LEVELS *****                             --
    -- -------------------------------------------------------------------------- --
    if terminal and DieselEngine.ShowLevels and parts.dcm ~= nil and parts.dcm.ConditionPercentage > 1 then
        terminal.ClearHistory()
        -- SHOW: Status - only display if there is a terminal, ignition is implicit
        if dieselEngine.combustion == true then
            --terminal.SendMessage("*COMBUSTION: " .. MT.HF.Round(DieselEngine.generatedHP, 0) .. "kW GENERATED*", Color(255,100,50,255))
            --terminal.SendMessage("Temperature: " .. MT.HF.Round(thermal.Temperature, 0) .. "F", MT.DF.getTemperatureZone(thermal.Temperature, DieselEngine.OperatingTemperature, "color"))
            --terminal.SendMessage(string.format("%-5s", MT.HF.Round(DieselEngine.CoolantLevel * 100, 1) .. "%") .. " coolant.", Color(150,255,175,255))

        end
    end
    -- -------------------------------------------------------------------------- --
    --                           ***** DIAGNOSTICS *****                          --
    -- -------------------------------------------------------------------------- --
    if terminal and DieselEngine.DiagnosticMode and parts.dcm ~= nil and parts.dcm.ConditionPercentage > 1 then
        terminal.ClearHistory()
        -- DIAGNOSTICS: Status - only display if there is a terminal, ignition is implicit
        if dieselEngine.combustion == true then
            terminal.SendMessage("*COMBUSTION: " .. MT.HF.Round(DieselEngine.generatedHP, 0) .. "kW GENERATED*", Color(255,100,50,255))
            terminal.SendMessage("Temperature: " .. MT.HF.Round(thermal.Temperature, 0) .. "F", MT.DF.getTemperatureZone(thermal.Temperature, DieselEngine.OperatingTemperature, "color"))
            terminal.SendMessage("Heat Generated: " .. MT.HF.formatNumber(MT.HF.Round(DieselEngine.HeatGenerated, 0)) .. "BTU", Color(255,100,50,255))
            terminal.SendMessage("Cooling Needed: " .. MT.HF.formatNumber(MT.HF.Round(DieselEngine.CoolingNeeded, 0)) .. "BTU", Color.Gray)
            terminal.SendMessage("Cooling Available: " .. MT.HF.formatNumber(MT.HF.Round(DieselEngine.CoolingAvailable, 0)) .. "BTU", Color.Gray)
            terminal.SendMessage("Heat Surplus: " .. MT.HF.formatNumber(MT.HF.Round(DieselEngine.HeatSurplus, 0)) .. "BTU", Color.Gray)

            --terminal.SendMessage(string.format("%-5s", dieselEngine.fuelTime .. "m") .. " of Diesel Fuel remaining", Color(255,150,0,255))
            --terminal.SendMessage(string.format("%-5s", dieselEngine.oilTime .. "m") .. " of Oil remaining.", Color(255,150,0,255))
            --terminal.SendMessage(string.format("%-5s", dieselEngine.filterTime .. "m") .. " of Oil Filtration remaining.", Color(255,150,0,255))
            --terminal.SendMessage(string.format("%-5s", dieselEngine.oxygenTime .. "m") .. " of Oxygen remaining.", Color(255,150,0,255))
        end
        -- DIAGNOSTICS: Error Codes - only display if the generator IsOn and there are errorCodes
        if next(MT.itemCache[item].diagnosticData.errorCodes) ~= nil then
            terminal.SendMessage("*****COMBUSTION FAILED*****",  Color(255, 35, 35, 255))
            for k, dCode  in pairs(MT.itemCache[item].diagnosticData.errorCodes) do
                terminal.SendMessage(dCode, Color(255, 35, 35,255))
            end
        end
        -- DIAGNOSTICS: Warning Codes - only display if the generator IsOn and there are warningCodes
        if next(MT.itemCache[item].diagnosticData.warningCodes) ~= nil then
            terminal.SendMessage("*****WARNINGS*****",  Color(255, 80, 50, 255))
            for k, dCode in pairs(MT.itemCache[item].diagnosticData.warningCodes) do
                terminal.SendMessage(dCode, Color(255, 80, 50, 255))
            end
        end
    end
    return DieselEngine
end
