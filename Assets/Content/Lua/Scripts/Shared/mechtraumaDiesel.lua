MT.DF = {}

function MT.DF.airFilterCheck(item, dieselSeries, airFilter)
    local airFilterCheck = true -- defaults to true for dieselSeries with no airFilter

    -- did I get wet?
    if item.InWater and airFilter ~= nil then
        airFilter.AddTag("wet")
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
        elseif airFilter.HasTag("wet") then
            airFilterCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1012: AIR FILTER BLOCKED*")
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1013: AIR FILTER WET*")        
        end
    end
    return airFilterCheck
end

function MT.DF.compressionCheck(item, dieselSeries, engineBlock, cylinderHead, crankAssembly)
    local compressionCheck = true -- defaults to true for dieselSeries with no engineBlock
    if dieselSeries.engineBlockLocation then
        if engineBlock == nil or cylinderHead == nil or crankAssembly == nil then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1018: FAILED COMPRESSION CHECK*")
            compressionCheck = false
        elseif engineBlock.ConditionPercentage < 1 or engineBlock.HasTag("cracked") or cylinderHead.ConditionPercentage < 1 or crankAssembly.ConditionPercentage < 1 then
            compressionCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1018: FAILED COMPRESSION CHECK*")
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
        elseif fuelFilter.ConditionPercentage < 1 or fuelFilter.HasTag("blocked") then
            fuelPressureCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1010: LOW FUEL PRESSURE*")
        end
    end
    -- check fuelPump
    if dieselSeries.fuelPumpLocation then
        if fuelPump == nil then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1014: LOW FUEL PRESSURE*")
            fuelPressureCheck = false
        elseif fuelPump.ConditionPercentage < 1 or fuelPump.HasTag("blocked") then
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

function MT.DF.getFluids(item, dieselSeries)
    local index = 0
    local fluids = {oilItems = {}, oilVol = 0, frictionReduction = 0}

    -- DYNAMIC INVENTORY: loop through the inventory and see what we have    
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


function MT.DF.getParts(item, dieselSeries)
    local index = 0
    local parts = {oilFilterItems = {}, oilFilterCount = 0, oilFilterVol = 0}
    parts.oilFiltrationSlots = dieselSeries.oilFilterSlots
    parts.oilFiltrationVol = 0

    -- STATIC INVENTORY PARTS: add any staticly located items to the parts inventory

    -- fuelFilter (if any)
    if dieselSeries.fuelFilterLocation and item.OwnInventory.GetItemAt(dieselSeries.fuelFilterLocation) ~= nil then parts.fuelFilter = item.OwnInventory.GetItemAt(dieselSeries.fuelFilterLocation) end
    -- fuelPump (if any)
    if dieselSeries.fuelPumpLocation and item.OwnInventory.GetItemAt(dieselSeries.fuelPumpLocation) ~= nil then parts.fuelPump = item.OwnInventory.GetItemAt(dieselSeries.fuelPumpLocation) end
    -- airFilter (if any)
    if dieselSeries.airFilterLocation and item.OwnInventory.GetItemAt(dieselSeries.airFilterLocation) ~= nil then parts.airFilter = item.OwnInventory.GetItemAt(dieselSeries.airFilterLocation) end
    -- battery (if any)
    if dieselSeries.batteryLocation and item.OwnInventory.GetItemAt(dieselSeries.batteryLocation) ~= nil then parts.battery = item.OwnInventory.GetItemAt(dieselSeries.batteryLocation) end
    -- starterMotor (if any)
    if dieselSeries.starterMotorLocation and item.OwnInventory.GetItemAt(dieselSeries.starterMotorLocation) ~= nil then parts.starterMotor = item.OwnInventory.GetItemAt(dieselSeries.starterMotorLocation) end
    -- exhaustManifold (if any)
    if dieselSeries.exhaustManifoldLocation and item.OwnInventory.GetItemAt(dieselSeries.exhaustManifoldLocation) ~= nil then parts.exhaustManifold = item.OwnInventory.GetItemAt(dieselSeries.exhaustManifoldLocation) end
    -- exhaustManifoldGasket (if any)
    if dieselSeries.exhaustManifoldLocation and parts.exhaustManifold ~= nil and parts.exhaustManifold.OwnInventory.GetItemAt(0) ~= nil then parts.exhaustManifoldGasket = parts.exhaustManifold.OwnInventory.GetItemAt(0) end
    -- dcm (if any)
    if dieselSeries.dcmLocation and item.OwnInventory.GetItemAt(dieselSeries.dcmLocation) ~= nil then
        parts.dcm = item.OwnInventory.GetItemAt(dieselSeries.dcmLocation)
        if parts.dcm.OwnInventory.GetItemAt(2) ~= nil then parts.oxygenSensor = parts.dcm.OwnInventory.GetItemAt(2) end
        if parts.dcm.OwnInventory.GetItemAt(3) ~= nil then parts.pressureSensor = parts.dcm.OwnInventory.GetItemAt(3) end
    end
    -- engineBlock (if any)
    if dieselSeries.engineBlockLocation and item.OwnInventory.GetItemAt(dieselSeries.engineBlockLocation) ~= nil then
        parts.engineBlock = item.OwnInventory.GetItemAt(dieselSeries.engineBlockLocation)
        if dieselSeries.cylinderHeadLocation and parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.cylinderHeadLocation) then
            parts.cylinderHead = parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.cylinderHeadLocation)
        end
        if dieselSeries.crankAssemblyLocation and parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.crankAssemblyLocation) then
            parts.crankAssembly = parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.crankAssemblyLocation)
        end
    end

    -- DYNAMIC INVENTORY: loop through the inventory and see what we have    
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
