local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

--[[
    @desc: 派发事件
    author:{author}
    time:2018-11-09 14:11:31
    --@eventName: 事件名称
	--@data: 数据
    @return:
]]
function cc.exports.dispatchEvent(eventName, data)
    local event = cc.EventCustom:new(eventName)
    event.data = data
    eventDispatcher:dispatchEvent(event)
end

--[[
    @desc: 注册事件在节点上，不会自动移除。 根据场景优先级
            一般注册到当前场景下，场景销毁的时候手动执行反注册
    author:{author}
    time:2018-11-09 14:12:03
    --@eventName: 事件名称
	--@callback: 回调
	--@node: 要注册的节点
    @return:
]]
function cc.exports.registEventByNode(eventName, callback, node)
    local listener = cc.EventListenerCustom:create(eventName, function(event)
        callback(event.data)
    end)
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
    return listener
end

--[[
    @desc: 根据名称注册全局事件。根据固定优先级
    author:{author}
    time:2018-11-09 14:13:50
    --@eventName: 事件名称
	--@callback: 回调
	--@fixedPriority: 事件优先级
    @return:
]]
function cc.exports.registEventByName(eventName, callback, fixedPriority)
    local listener = cc.EventListenerCustom:create(eventName, function(event)
        callback(event.data)
    end)
    eventDispatcher:addEventListenerWithFixedPriority(listener, fixedPriority or 1)
    return listener
end

--[[
    @desc: 注册事件，根据obj判断哪种注册方式
    author:{author}
    time:2018-11-09 14:14:31
    --@eventName:
	--@callback:
	--@obj: 
    @return:
]]
function cc.exports.registEvent(eventName, callback, obj)
    if type(obj) == "number" or type(obj) == "nil" then
        return registEventByName(eventName, callback, obj)
    else
        return registEventByNode(eventName, callback, obj)
    end
end

--[[
    @desc: 移除某个节点上的所有事件
    author:{author}
    time:2018-11-09 14:15:01
    --@node: 
    @return:
]]
function cc.exports.reomveEventByNode(node)
    eventDispatcher:removeEventListenersForTarget(node)
end

--[[
    @desc: 根据名称移除单个事件
    author:{author}
    time:2018-11-09 14:15:24
    --@eventName: 
    @return:
]]
function cc.exports.removeEventByName(eventName)
    eventDispatcher:removeCustomEventListeners(eventName)
end

--[[
    @desc: 根据obj的类型判断采用哪种移除方式
    author:{author}
    time:2018-11-09 14:44:51
    --@obj: 
    @return:
]]
function cc.exports.removeEvent(obj)
    if type(obj) == "string" then
        removeEventByName(obj)
    else
        reomveEventByNode(obj)
    end
end