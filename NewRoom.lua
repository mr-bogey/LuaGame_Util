local UI = import("babe/ui/widget")

local NewRoom = class(UI.View)

local WIDTH, HEIGHT = 51, 51

local function getRandomNum(min, max)
	if not max then
		min, max = 1, min
	end
	return math.modf(math.random(min, max))
end

local function rect(x, y, width, height)
    if type(x) == "table" and type(y) == "table" then
        return {x = x.x, y = x.y, width = y.width, height = y.height}
    end
    return {x = x, y = y, width = width, height = height}
end

local function p(x, y)
    return {x = x, y = y}
end

local function pSub(p1, p2)
	return p(p1.x - p2.x, p1.y - p2.y)
end

local function pAdd(p1, p2)
	return p(p1.x + p2.x, p1.y + p2.y)
end

local function size(width, height)
    return {width = width, height = height}
end

local function isPosInRect(pos, rect)
    if pos.x >= rect.x and pos.y >= rect.y and pos.x <= (rect.x + rect.width) and pos.y <= (rect.y + rect.height) then
        return true
    end
    return false
end

local MapType = {
    empty = 0,
    road = 1,
    room = 2,
	door = 3,
	debug = 10,
}

local Colr = {
	[MapType.empty] = Color(20,20,20),
	[MapType.road] = Color(120,120,120),
	[MapType.room] = Color(255,255,255),
	[MapType.door] = Color(255,255,0),
	[MapType.debug] = Color(40,20,20)
}

local function dumpMap(tb, parent)
	for i,v in ipairs(tb) do
	    for j,k in ipairs(v) do
	        local widget = UI.View{
				width = 10,
				height = 10,
				top = j * 11,
				left = i * 11,
				background_color = Colr[k],
				position_type = 1
			}
			parent:add(widget)
	    end
	end
end

local function initMap(width, height)
	height = height or width
    local tb = {}
    for i = 1, width do
        tb[i] = {}
        for j = 1, height do
            tb[i][j] = MapType.empty
        end
    end
    return tb
end

function NewRoom:ctor(parent)
    self.roomMap = initMap(WIDTH, HEIGHT)
	print(os.clock())
    self.roomList = self:createRoom()
	print(os.clock())
	self.roadList = self:createRoad()
	print(os.clock())
	self.doorList = self:selectDoor()
	print(os.clock())
	self:fixRoomMap()
	print(os.clock())

    dumpMap(self.roomMap, parent)
end

function NewRoom:createRoom()
	local function getRandomSingleNum(min, max)
	    if not max then
	        min, max = 1, min
	    end
	
	    local num = math.modf(math.random(min, max))
	    if num % 2 == 0 then
	        num = num + 1
	    end
	    return num
	end

	local function isRectCapRect(rect, pRect)
	    if rect.x + rect.width < pRect.x or rect.x > pRect.x + pRect.width or
	        rect.y + rect.height < pRect.y or rect.y > pRect.y + pRect.height then
	        return false
	    end
	    return true
	end

    local roomList = {}
	local index = 1
    while index <= 10 do
        local size = size(getRandomSingleNum(3, 7), getRandomSingleNum(3, 7))
        local pos = p(getRandomSingleNum(WIDTH - size.width - 1), getRandomSingleNum(HEIGHT - size.height - 1))
        local room = rect(pos, size)
        local flag = true
        for i,v in ipairs(roomList) do
            if isRectCapRect(room, v) then
                flag = false
                break
            end
        end
        if flag then
            table.insert(roomList, room)
            for i = room.x, room.x + room.width - 1 do
                for j = room.y, room.y + room.height - 1  do
                    self.roomMap[i][j] = MapType.room
                end
            end
        end
		index = index + 1
    end
    return roomList
end

function NewRoom:createRoad()
	local roomMap = self.roomMap

	local function Road(pos, pPos)
		return {pos = pos, pPos = pPos}
	end
	
	--根据父节点位置检测当前点受否可用
	local function checkPosAround(pos, pPos)
		if pPos then
			local disPos = pSub(pAdd(pos, pos), pPos)
			if roomMap[disPos.x] and roomMap[disPos.x][disPos.y] and roomMap[disPos.x][disPos.y] ~= MapType.empty then
				return false
			end
		else
			local disPos = {
				[1] = p(0, 1),
				[2] = p(1, 0),
				[3] = p(0, -1),
				[4] = p(-1, 0)
			}
			for i,v in ipairs(disPos) do
				local newPos = pAdd(pos, v)
			    if roomMap[newPos.x] and roomMap[newPos.x][newPos.y] and roomMap[newPos.x][newPos.y] ~= MapType.empty then
			    	return false
			    end
			end
		end
		return true
	end
	
	--获取一个空位置
	local function getAnEmptyPos()
		for i,v in ipairs(roomMap) do
		    for j,k in ipairs(v) do
		        if i % 2 == 1 and j % 2 == 1 and k == MapType.empty and checkPosAround(p(i,j)) then
		        	return p(i,j)
		        end
		    end
		end
	end
	
	--获取当前道路的延伸道路，并分组
	local function getNextRoad(road)
		if road.pos.x % 2 == 0 or road.pos.y % 2 == 0 then
			local disPos = pSub(road.pos, road.pPos)
			return Road(pAdd(road.pos, disPos), road.pos)
		else
			local disPos = {
				[1] = p(0, 1),
				[2] = p(1, 0),
				[3] = p(0, -1),
				[4] = p(-1, 0)
			}
			local roads = {}
			for i,v in ipairs(disPos) do
				local newPos = pAdd(road.pos, v)
			    if roomMap[newPos.x] and roomMap[newPos.x][newPos.y] and checkPosAround(newPos, road.pos) then
			    	table.insert(roads, Road(newPos, road.pos))
			    end
			end
			local newRoad
			if #roads > 0 then
				newRoad = table.remove(roads, getRandomNum(#roads))
			end
			return newRoad, roads
		end
	end
	
	local pos = getAnEmptyPos()
	if not pos then
		return
	end
	
	local roadList = {pos}
	local otherRoads = {}
	local road = Road(pos)
	while road do
		roomMap[road.pos.x][road.pos.y] = MapType.road
	 	local nextRoad, otherRoad = getNextRoad(road)
		if not nextRoad then
			table.insert(roadList, road.pos)
		end
		while not nextRoad and #otherRoads > 0 do
		 	nextRoad = table.remove(otherRoads, #otherRoads)
			if not checkPosAround(nextRoad.pos, nextRoad.pPos) then
				nextRoad = nil
			end
		end
		if not nextRoad then
			local pos = getAnEmptyPos()
			if pos then
				nextRoad = Road(pos)
			end
		end
		
		if otherRoad and #otherRoad > 0 then
			for k,v in ipairs(otherRoad) do
				table.insert(otherRoads, v)
			end
		end
		road = nextRoad
	end
	return roadList
end

function NewRoom:selectDoor()
	local function isDoor(pos)
		local disPos = {
			[1] = {p(0, 1), p(0, -1)},
			[2] = {p(-1, 0), p(1, 0)}
		}
		for k,v in ipairs(disPos) do
		    local pos1 = pAdd(pos, v[1])
			local pos2 = pAdd(pos, v[2])
			if self.roomMap[pos1.x] and self.roomMap[pos1.x][pos1.y] and self.roomMap[pos2.x] and self.roomMap[pos2.x][pos2.y] then
				if (self.roomMap[pos1.x][pos1.y] == MapType.road and self.roomMap[pos2.x][pos2.y] == MapType.room)
					or (self.roomMap[pos1.x][pos1.y] == MapType.room and self.roomMap[pos2.x][pos2.y] == MapType.road) then
					return true
				elseif (self.roomMap[pos1.x][pos1.y] == MapType.room and self.roomMap[pos2.x][pos2.y] == MapType.room) then
					return nil
				end
			end
		end
		return false
	end

	for _,v in ipairs(self.roomList) do
		local doors = {}
		for i = v.x - 1, v.x + v.width do
			for j = v.y - 1, v.y + v.height do
				if self.roomMap[i] and self.roomMap[i][j] and self.roomMap[i][j] == MapType.empty and isDoor(p(i,j)) ~= false then
					table.insert(doors, p(i,j))
					--self.roomMap[i][j] = MapType.debug
				end
			end
		end
		for i = 1, (getRandomNum(10) == 1 and 2 or 1) do
			local door = table.remove(doors, getRandomNum(#doors))
			self.roomMap[door.x][door.y] = MapType.door
		end
	end
end

function NewRoom:fixRoomMap()
	local function checkPos(pos)
		local disPos = {
			[1] = p(0, 1),
			[2] = p(1, 0),
			[3] = p(0, -1),
			[4] = p(-1, 0)
		}
		local num = 0
		local pPos
		for i,v in ipairs(disPos) do
			local newPos = pAdd(pos, v)
		    if self.roomMap[newPos.x] and self.roomMap[newPos.x][newPos.y] and self.roomMap[newPos.x][newPos.y] ~= MapType.empty then
		    	num = num + 1
				if num >= 2 then
					return false
				end
				pPos = newPos
		    end
		end
		if num == 0 then
			return false
		end
		return true, pPos
	end

	for i,v in ipairs(self.roadList) do
		local pos = v
    	local bool, pPos = checkPos(pos)
		while bool do
			self.roomMap[pos.x][pos.y] = MapType.empty
			pos = pPos
			bool, pPos = checkPos(pos)
		end
    end
end

return NewRoom