# SignalU
A lightweight, high-performance Signal implementation for Roblox Luau, designed to act as a drop-in alternative to BindableEvent and RBXScriptSignal with additional safety, performance, and flexibility.

This module includes an efficient linked list connection system, coroutine pooling for async handlers, and parallel execution support for multi-threaded scripts.

# ~ Features
- Optimized Linked List Connections – Fast connect/disconnect operations.
- Coroutine Reuse System – Efficiently manages threads for async event calls.
- Parallel Execution Support – Safely handles event firing in Actor environments.
- Strict Mode (Optional) – Warns when ConnectParallel is used outside a parallel context.
- Utility Functions – Includes GetInstanceFromPath for path-based lookups.
- Full Type Safety – Uses Luau’s strict type annotations for reliability.


# ~ Example Usage
```luau
local Signal = require(path.to.SignalU)

-- Create a simple event
local onHit = Signal()

-- Connect a listener
onHit:Connect(function(player)
	print(player.Name .. " was hit!")
end)

-- Fire the event
onHit:Fire(game.Players.LocalPlayer)

-- Async firing
onHit:FireAsync(game.Players.LocalPlayer)

-- Disconnect all listeners
onHit:DisconnectAll()
```

# ~ API Reference
**`Signal(strictCheck: boolean?`)**
- Creates a new signal.
- If strictCheck is true, parallel-only environments are enforced.
**`Signal:Connect(fn)`**
- Connects a listener to the signal.
**`Signal:Once(fn)`**
- Connects a listener that disconnects automatically after one trigger.
**`Signal:ConnectParallel(fn)`**
- Runs the listener in a desynchronized task (for use in parallel code).
**`Signal:Fire(...any)`**
- Fires all connected listeners synchronously.
**`Signal:FireAsync(...any)`**
- Fires listeners asynchronously using pooled threads.
**`Signal:Wait()`**
- Yields until the next Fire call.
**`Signal:DisconnectAll()`**
- Removes all connections.
**`Signal:Destroy()`**
- Destroys the signal and clears its connections.
**`SignalU.IsSignal(object)`**
- Utility method to check if an object is a Signal.
