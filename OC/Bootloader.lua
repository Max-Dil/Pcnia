OC = {
    path = ...,
}

function OC:init(data)
    Processor = data.processor
    data.processor:init()
    MB = data.mother:init(data.processor)
    data.processor.motherboard = MB
    RAM = data.ram:init(MB)
    Cooler = data.cooler:init(data.processor, MB)
    MB:attachCooler(Cooler)
    PSU = data.blockEnergy:init(MB)
    GPU = data.gpu:init(data.processor)
    MONITOR = data.monitor:init(GPU)
    data.processor:setGPU(GPU)
    MB.gpu = GPU
    MB.monitor = MONITOR
    HDD = data.disk:init(MB)
    MB:attachStorage(HDD)
end

function OC:update(dt)
    PSU:update(dt)
    MB:update(dt)
    RAM:update(dt)
    Cooler:update(dt)
    Processor:update(dt)
    GPU:update(dt)
    MONITOR:update(dt)
    HDD:update(dt)
end

return OC