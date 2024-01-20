﻿using Barotrauma;
using Barotrauma.Items.Components;

namespace Mechtrauma.TransferSystems;

public partial class SteamBoiler : Powered, IFluidDevice
{
    #region VARS

    private int _updateWaitTickRemaining = 0;
    private readonly LiquidContainer _inletWaterContainer = new();
    private readonly VaporContainer _outletSteamContainer = new();

    #endregion
    
    public SteamBoiler(Item item, ContentXElement element) : base(item, element)
    {
        this.IsActive = true;
    }
    
    public IReadOnlyList<T> GetFluidContainers<T>() where T : class, IFluidContainer, new()
    {
        throw new NotImplementedException();
    }

    public IReadOnlyList<T> GetFluidContainersByGroup<T>(string groupName) where T : class, IFluidContainer, new()
    {
        throw new NotImplementedException();
    }

    public T GetPrefContainerByGroup<T>(string groupName) where T : class, IFluidContainer, new()
    {
        throw new NotImplementedException();
    }

    public FluidProperties.PhaseType OutputPhaseType { get; protected set; }
    public FluidProperties.PhaseType InputPhaseType { get; protected set; }

    public override float GetCurrentPowerConsumption(Connection connection = null)
    {
        return base.GetCurrentPowerConsumption(connection);
    }

    public override void OnMapLoaded()
    {
        base.OnMapLoaded();
    }

    public override void Update(float deltaTime, Camera cam)
    {
        base.Update(deltaTime, cam);
        _updateWaitTickRemaining--;
        if (_updateWaitTickRemaining < 1)
        {
            _updateWaitTickRemaining = IFluidDevice.WaitTicksBetweenUpdates;
            UpdateSteamGeneration();
        }
    }

    private void UpdateSteamGeneration()
    {
        // convert liquid to vapor
        
    }
}