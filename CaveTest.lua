local CaveTest = class("CaveTest", cc.load("mvc").ViewBase)

local WIDTH = 30
local HEIGHT = 30

local function isWall(i, j)
    if i == 1 or j == 1 or i == WIDTH or j == HEIGHT then
        return true
    end
    return math.random(1, 100) > 60
end

local function formatMap(map)
    local function getAroundWallNum(x, y)
        local wallNum = 0
        local allWallNum = 0
        for i = x - 2, x + 2 do
            for j = y - 2, y + 2 do
                if math.abs(i - x) == 2 or math.abs(j - y) == 2 then
                    if map[i] and map[i][j] then
                        allWallNum = allWallNum + 1
                    end
                    if map[i] == nil or map[i][j] == nil then
                        allWallNum = allWallNum + 1
                    end
                else
                    if map[i] and map[i][j] then
                        wallNum = wallNum + 1
                        allWallNum = allWallNum + 1
                    end
                    if map[i] == nil or map[i][j] == nil then
                        wallNum = wallNum + 1
                        allWallNum = allWallNum + 1
                    end
                end
                
            end
        end
        return wallNum, allWallNum
    end

    local newMap = {}
    for i,v in ipairs(map) do
        newMap[i] = {}
        for j,k in ipairs(v) do
            local wallNum, allWallNum = getAroundWallNum(i, j)
            if wallNum >= 5 then
                newMap[i][j] = true
            elseif allWallNum <= 2 then
                newMap[i][j] = true
            else
                newMap[i][j] = false
            end
        end
    end
    return newMap
end

local nodeWidth = 10
local function drawMap(drawNode, map)
    drawNode:clear()
    for i,v in ipairs(map) do
        for j,k in ipairs(v) do
            local x = i * nodeWidth
            local y = j * nodeWidth
            if not k then
                drawNode:drawSolidRect(cc.p(x, y), cc.p(x + nodeWidth - 1, y + nodeWidth - 1), cc.c4f(0.95,1,1,1))
            else
                drawNode:drawSolidRect(cc.p(x, y), cc.p(x + nodeWidth - 1, y + nodeWidth - 1), cc.c4f(0.5,0.5,0.5,1))
            end
        end
    end
end

function CaveTest:onCreate()
    local drawNode = cc.DrawNode:create()
    drawNode:addTo(self):align(display.LEFT_BOTTOM, cc.p(0, 0))

    local map = {}
    for i = 1, WIDTH do
        map[i] = {}
        for j = 1, HEIGHT do
            map[i][j] = isWall(i, j)
        end
    end

    local layer = cc.Layer:create()
    layer:addTo(self):align(display.LEFT_BOTTOM, cc.p(0, 0))
    layer:onTouch(function (event)
        if event.name == "began" then
            map = formatMap(map)
            drawMap(drawNode, map)
        end
    end)
    drawMap(drawNode, map)
end

return CaveTest