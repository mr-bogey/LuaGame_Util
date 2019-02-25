
local LightTest = class("LightTest", cc.load("mvc").ViewBase)

local function getPolygonByPos(pos)
    for i = 1, 4 do
        local width = math.random(50, 100)
        local height = math.random(50, 100)
        return {pos, cc.pAdd(pos, cc.p(0, height)), cc.pAdd(pos, cc.p(width, width)), cc.pAdd(pos, cc.p(width, 0))}
    end
end

function LightTest:onCreate()
    local polygons = self:createPolygons()
    self.dot = cc.DrawNode:create()
    self.dot:addTo(self):align(display.CENTER, display.center)
    self.dot:drawDot(cc.p(0, 0), 2, cc.c4f(1, 1, 1, 1))
    self.drawNode = cc.DrawNode:create(0.5)
    self.drawNode:addTo(self):align(display.LEFT_BOTTOM, cc.p(0, 0))
    self.layer = cc.Layer:create()
    self.layer:addTo(self):align(display.LEFT_BOTTOM, cc.p(0, 0))
    self.layer:setContentSize(display.size)
    self.layer:onTouch(function(event)
        if event.name == "began" or event.name == "moved" then
            local pos = cc.p(event.x, event.y)
            self.dot:setPosition(pos)
            self:refreshLight(polygons, pos)
            return true
        end
    end)
end

function LightTest:createPolygons()
    local polygons = {{cc.p(30, 30), cc.p(30, display.height-60), cc.p(display.width-60, display.height-60), cc.p(display.width-60, 30)}}
    local baseWidth = display.width / 4
    local baseHeight = display.height / 4
    local posTb = {
        cc.p(baseWidth * 2, baseHeight * 2), 
        cc.p(baseWidth, baseHeight), 
        cc.p(baseWidth * 3, baseHeight), 
        cc.p(baseWidth, baseHeight * 3), 
        cc.p(baseWidth * 3, baseHeight * 3)
    }
    local drawNode = cc.DrawNode:create()
    drawNode:addTo(self):align(display.LEFT_BOTTOM, cc.p(0, 0))
    for i,v in ipairs(posTb) do
        local points = getPolygonByPos(v)
        drawNode:drawPolygon(points, #points, cc.c4f(1, 1, 0, 0.2), 1, cc.c4f(1, 0, 0, 0.1))
        table.insert(polygons, points)
    end
    return polygons
end

local function pGetIntersectPoint(pt1,pt2,pt3,pt4)
    local s,t, ret = 0,0,false
    ret,s,t = cc.pIsLineIntersect(pt1,pt2,pt3,pt4,s,t)
    if ret and s > 1 then
        if t > 0 and t < 1 then
            return cc.p(pt1.x + s * (pt2.x - pt1.x), pt1.y + s * (pt2.y - pt1.y)), 1
        elseif t == 0 or t == 1 then
            return cc.p(pt1.x + s * (pt2.x - pt1.x), pt1.y + s * (pt2.y - pt1.y)), 2
        end
    elseif ret and s >= 0 and s <= 1 then
        if t > 0 and t < 1 then
            return cc.p(pt1.x + s * (pt2.x - pt1.x), pt1.y + s * (pt2.y - pt1.y)), 3
        elseif t == 0 or t == 1 then
            return cc.p(pt1.x + s * (pt2.x - pt1.x), pt1.y + s * (pt2.y - pt1.y)), 4
        end
    end
    return nil
end

local function getLightLines(polygons, basePos)
    local function getNearestPos(posTb)
        local minLen, pos
        for i,v in ipairs(posTb) do
            local len = cc.pGetDistance(basePos, v)
            if not minLen then
                minLen = len
                pos = v
            else
                if minLen > len then
                    minLen = len
                    pos = v
                end
            end
        end
        return pos
    end

    local lines = {}
    for i,v in ipairs(polygons) do
        for i = 1, #v do
            local line = {v[i], (v[i+1] or v[1])}
            table.insert(lines, line)
        end
    end
    local newLines = {}
    for i,v in ipairs(polygons) do
        for j,k in ipairs(v) do
            local posTb = {cc.p(k.x - 0.1, k.y), k, cc.p(k.x + 0.1, k.y)}
            for o,p in ipairs(posTb) do
                local crossPos = {{}, {}, {}, {}}
                for m,n in pairs(lines) do
                    local pos, type = pGetIntersectPoint(basePos, p, unpack(n))
                    if pos then
                        table.insert(crossPos[type], pos)
                    end
                end
                -- 3,4,1,2
                local pos
                if #crossPos[3] > 0 then
                    pos = getNearestPos(crossPos[3])
                elseif #crossPos[4] > 0 then
                    pos = getNearestPos(crossPos[4])
                elseif #crossPos[1] > 0 then
                    pos = getNearestPos(crossPos[1])
                elseif #crossPos[2] > 0 then
                    pos = getNearestPos(crossPos[2]) 
                end
                if pos then
                    table.insert(newLines, {basePos, pos})
                end
            end
        end
    end
    table.sort(newLines, function (a, b)
        local aAngle = cc.pGetAngle(cc.pSub(a[2], a[1]), cc.p(0, 1))
        if aAngle < 0 then
            aAngle = math.pi * 2 + aAngle
        end
        local bAngle = cc.pGetAngle(cc.pSub(b[2], b[1]), cc.p(0, 1))
        if bAngle < 0 then
            bAngle = math.pi * 2 + bAngle
        end
        return aAngle < bAngle
    end)

    return newLines
end

function LightTest:refreshLight(polygons, basePos)
    local drawNode = self.drawNode
    drawNode:clear()
    local basePoss = {
        -- cc.p(basePos.x - 10, basePos.y),
        -- cc.p(basePos.x + 10, basePos.y),
        -- cc.p(basePos.x, basePos.y - 10),
        -- cc.p(basePos.x, basePos.y + 10),
        basePos
    }

    for j,k in ipairs(basePoss) do
        local lines = getLightLines(polygons, k)
        local point = lines[#lines][2]
        local points = {}
        for i,v in ipairs(lines) do
            -- drawNode:drawLine(v[1], v[2], cc.c4f(0,1,1,1))
            drawNode:drawPolygon({k, point, v[2]}, 3, cc.c4f(1,1,1,0.05), 1, cc.c4f(0,0,1,0))
            point = v[2]
            if #points <= 0 or math.abs(point.x - points[#points].x) > 1 or math.abs(point.y - points[#points].y) > 1 then
                table.insert(points, point)
            end
        end
        if self.clip then
            return
        end
        local sp = cc.Sprite:create("HelloWorld.png")
        sp:align(display.LEFT_BOTTOM, cc.p(0, 0))
        local clip = cc.ClippingNode:create(drawNode)
        clip:addChild(sp)
        clip:addTo(self):align(display.LEFT_BOTTOM, cc.p(0, 0))
        self.clip = clip

        -- drawNode:removeAllChildren()
        -- for i,v in ipairs(points) do
        --     drawNode:drawDot(v, 2, cc.c4f(1,0,0,1))
        --     cc.Label:createWithSystemFont(string.format("i = %d\nx = %d\ny = %d", i, v.x, v.y), "", 10):addTo(drawNode):align(display.CENTER, v)
        -- end
    end
end

return LightTest