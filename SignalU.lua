local FreeRunnerThread = nil :: thread?

local function AcquireFreeThreadAndCallEventHandler(fn: (...any) -> (), ...: any)
	local Thread = FreeRunnerThread
	FreeRunnerThread = nil
	fn(...)
	FreeRunnerThread = Thread
	Thread = nil
end

local function RunEventHandlerInFreeThread()
	while true do
		AcquireFreeThreadAndCallEventHandler(coroutine.yield())
	end
end

local function HelperThreadSpawner(taskfn, fn: (...any) -> (), ...: any)
	if not FreeRunnerThread then
		FreeRunnerThread = coroutine.create(RunEventHandlerInFreeThread)
		coroutine.resume(FreeRunnerThread :: any)
	end
	taskfn(FreeRunnerThread :: any, fn, ...)
end

local function Spawn(fn: (...any) -> (), ...: any)
	HelperThreadSpawner(task.spawn, fn, ...)
end

local function GetInstanceFromPath(path: string): Instance?
	local current = game
	for segment in string.gmatch(path, "[^%.]+") do
		current = current:FindFirstChild(segment)
		if not current then return nil end
	end
	return current
end

---------------------------------------------------------------
-- Linked List Implementation
---------------------------------------------------------------

local Connection = {}
Connection.__index = Connection

function Connection:Disconnect()
	if not self.Connected then return end
	self.Connected = false

	local parent = self.Parent
	if not parent then return end

	if self.Prev then
		self.Prev.Next = self.Next
	else
		parent.Head = self.Next
	end

	if self.Next then
		self.Next.Prev = self.Prev
	end

	self.Next = nil
	self.Prev = nil
	self.Parent = nil
	self.Listener = nil
end

local Signal = {}
Signal.__index = Signal

local function CreateSignal<T...>(_, strictcheck: boolean?, ...: T...)
	local self = setmetatable({}, Signal)
	self.StrictCheck = strictcheck == true
	self.Head = nil :: Connection?
	return (self :: any) :: Signal<T...>
end

function Signal:Connect(fn)
	local connection = setmetatable({}, Connection)
	connection.Listener = fn
	connection.Connected = true
	connection.Parent = self

	if self.Tail then
		self.Tail.Next = connection
		connection.Prev = self.Tail
		self.Tail = connection
	else
		self.Head = connection
		self.Tail = connection
	end

	return connection
end


function Signal:Once(fn: (...any) -> ())
	local conn
	conn = self:Connect(function(...)
		fn(...)
		conn:Disconnect()
	end)
	return conn
end

function Signal:ConnectParallel(fn: (...any) -> ())
	if self.StrictCheck then
		local scriptPath = debug.info(coroutine.running(), 2, "s")
		if scriptPath then
			local scriptInstance = GetInstanceFromPath(scriptPath)
			if scriptInstance and scriptInstance:GetActor() == nil then
				warn(`Cannot use ConnectParallel in non-parallel environment ({scriptPath})`)
				return (nil :: any) :: Connection
			end
		end
	end
	return self:Connect(function(...)
		task.desynchronize()
		fn(...)
	end)
end

function Signal:Fire(...: any)
	local node = self.Head
	while node do
		if node.Connected then
			node.Listener(...)
		end
		node = node.Next
	end
end

function Signal:FireAsync(...: any)
	local node = self.Head
	while node do
		if node.Connected then
			Spawn(node.Listener, ...)
		end
		node = node.Next
	end
end

function Signal:Wait(): (...any)
	local co = coroutine.running()
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		coroutine.resume(co, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	self.Head = nil
	self.Tail = nil
end

function Signal:Destroy()
	self.Head = nil
	self.Tail = nil
	self.StrictCheck = nil :: any
	setmetatable(self, nil)
end

export type Connection = {
	Disconnect: (self: Connection) -> (),
	Connected: boolean,
	Parent: Signal?,
	Next: Connection?,
	Listener: (...any) -> ()
}

export type Signal<T...=()> = {
	Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	ConnectParallel: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	FireAsync: (self: Signal<T...>, T...) -> (),
	Wait: (self: Signal<T...>) -> (T...),
	DisconnectAll: (self: Signal<T...>) -> (),
	Destroy: (self: Signal<T...>) -> ()
}

local SignalU = setmetatable({
	IsSignal = function(object: any)
		return getmetatable(object) == Signal
	end,
}, { __call = CreateSignal })

return SignalU