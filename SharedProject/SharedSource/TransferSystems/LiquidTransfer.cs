﻿using Barotrauma;
using Barotrauma.Items.Components;

namespace Mechtrauma.TransferSystems;

public class LiquidTransfer : ItemComponent
{
    #region VARS

    [Editable, Serialize(true, IsPropertySaveable.Yes, "Are transfers enabled?")]
    public bool IsEnabled { get; set; }

    private float _maxFlowRate;
    [Editable, Serialize(float.MaxValue-1f, IsPropertySaveable.Yes, "Max flow rate (L).")]
    public float MaxFlowRate
    {
        get => _maxFlowRate;
        set => _maxFlowRate = Math.Max(0, value);
    }

    private float _pressureOutputRatio;

    [Editable(0.1f, 10f), Serialize(1f, IsPropertySaveable.Yes, "Exit/Outlet pressure adjustment multiplier.")]
    public float PressureOutputRatio
    {
        get => _pressureOutputRatio;
        set => _pressureOutputRatio = Math.Clamp(value, 0.1f, 10f);
    }
    
    public static readonly string SIGNAL_VOLUMETRIC_RATE = "output_flow_rate";
    public static readonly string SIGNAL_PRESSURE = "output_flow_rate";
    public static readonly string SIGNAL_VELOCITY = "output_velocity";

    private int _ticksUntilUpdate = 0;

    #endregion
    
    public LiquidTransfer(Item item, ContentXElement element) : base(item, element)
    {
        IsActive = true;
    }

    public override void OnItemLoaded()
    {
        base.OnItemLoaded();
        // randomize the initial count to stagger updates a bit and reduce lag spikes from network updates.
        _ticksUntilUpdate = Rand.Range(0, IFluidDevice.WaitTicksBetweenUpdates);    
    }

    public override void Update(float deltaTime, Camera cam)
    {
        base.Update(deltaTime, cam);
        if (IsEnabled)
        {
            _ticksUntilUpdate--;
            if (_ticksUntilUpdate < 1)
            {
                _ticksUntilUpdate = IFluidDevice.WaitTicksBetweenUpdates;
                UpdateLiquidTransfers();
            }
        }
    }

    /// <summary>
    /// The LiquidTransfer system is stateless so producer and consumers must be built every update. This is because
    /// there isn't a graceful way to track changed/dirty item connections outside of internal vanilla code.
    /// </summary>
    private void UpdateLiquidTransfers()
    {
        IFluidDevice? producer = null;
        List<IFluidDevice> consumers = new();

        if (TryGetProducerAndConsumers())
        {
            // get liquid containers
            var producerTank = producer!.GetPrefContainerByGroup<LiquidContainer>(ILiquidData.SymbolConnOutput);
            var consumerTanks = new List<LiquidContainer>();

            // exit if no src
            if (producerTank is null)
                return;
            
            // get valid consumers
            var sampleLiquid = producerTank.TakeFluidProportional<LiquidData>(0f).ToImmutableList();

            if (!sampleLiquid.Any())
                return;

            var sampleProperties = FluidDatabase.Instance.GetFluidProperties(sampleLiquid[0].Identifier,
                FluidProperties.PhaseType.Liquid);
            // for performance purposes, we take the acceleration ratio of the first fluid only. 
            // if needed, should be changed to take the acceleration from the highest volume fluid.
            // However, this requires withdrawing fluid pre-emptively.
            var sampleAccelRatio = sampleProperties?.AccelerationRatio ?? 0f;

            foreach (IFluidDevice device in consumers)
            {
                foreach (var container in device.GetFluidContainersByGroup<LiquidContainer>(ILiquidData.SymbolConnInput))       
                {
                    if (container is null)
                        continue;
                    if (container.Pressure - producerTank.Pressure > float.Epsilon) // back pressure excess
                        continue;
                    if (container.GetApertureSizeForConnection(ILiquidData.SymbolConnInput) < float.Epsilon) // valve closed
                        continue;
                    if (!container.CanPutFluids(sampleLiquid))
                        continue;
                    consumerTanks.Add(container);
                }
            }
            
            // calculate fluid proportions per container.          
            float sumProportions = 0;
            int tankCount = consumerTanks.Count;
            // calculate proportions
            // stack overflow protection limit of 128
            //Span<float> proportions = tankCount < 128 ? stackalloc float[tankCount] : new float[tankCount];
            Span<float> deltaPressures = tankCount < 128 ? stackalloc float[tankCount] : new float[tankCount];
            Span<float> apertures = tankCount < 128 ? stackalloc float[tankCount] : new float[tankCount];
            Span<float> velocities = tankCount < 128 ? stackalloc float[tankCount] : new float[tankCount];
            Span<float> toTransferVolume = tankCount < 128 ? stackalloc float[tankCount] : new float[tankCount];

            // calculate stats
            for (int i = 0; i < consumerTanks.Count; i++)
            {
                var tank = consumerTanks[i];
                deltaPressures[i] = producerTank.Pressure - tank.Pressure;
                apertures[i] = tank.GetApertureSizeForConnection(ILiquidData.SymbolConnInput);
                sumProportions += deltaPressures[i] * apertures[i]; 
                velocities[i] = producerTank.Velocity + deltaPressures[i] * sampleAccelRatio;
            }

            for (int i = 0; i < consumerTanks.Count; i++)
            {
                var proportion = deltaPressures[i] * apertures[i] / sumProportions; // get proportionate fluid transfer. range 0 > 1
                toTransferVolume[i] = Math.Min(producerTank.Volume,
                    consumerTanks[i].GetMaxFreeVolume<LiquidData, ImmutableList<LiquidData>>(sampleLiquid));
            }
            
            // calculate amount of volume to be sent to consumers
            
            
            // check against limits
            
            
            // send volume
            
        } 
    
        
        bool TryGetProducerAndConsumers()
        {
            bool success = false;
            try
            {
                bool foundInput = false;
                foreach (Connection connection in Item.Connections)
                {
                    if (connection.Name == ILiquidData.SymbolConnInput) // found input on self conn panel.
                    {
                        if (foundInput)
                            continue;
                        
                        foreach (Connection recipient in connection.Recipients)
                        {
                            if (foundInput)
                                break;
                            if (recipient.Name != ILiquidData.SymbolConnOutput) // we're skipping anything that isn't an liquid out connection.
                                continue;

                            foreach (ItemComponent component in recipient.Item.Components)  
                            {
                                // find the first compat IFluidDevice with an liquid out.
                                if (component is IFluidDevice { OutputPhaseType: FluidProperties.PhaseType.Liquid } device)    //outputs liquid
                                {
                                    // we found our producer.
                                    producer = device;
                                    foundInput = true;
                                    break;
                                }
                            }
                        }
                    }
                    else if (connection.Name == ILiquidData.SymbolConnOutput) // found output on self conn panel.
                    {
                        foreach (Connection recipient in connection.Recipients)
                        {
                            if (recipient.Name != ILiquidData.SymbolConnInput) // we're skipping anything that's not an input.
                                continue;

                            foreach (ItemComponent component in recipient.Item.Components)
                            {
                                if (component is IFluidDevice { InputPhaseType: FluidProperties.PhaseType.Liquid } device)
                                {
                                    consumers.Add(device);
                                }
                            }
                        }
                    }
                }

                success = true;
            }
            catch
            {
                success = false;
            }

            return success && producer is {} && consumers.Any();
        }
    }
}