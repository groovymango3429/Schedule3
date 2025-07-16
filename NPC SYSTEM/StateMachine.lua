local StateMachine = {}
StateMachine.__index = StateMachine

export type State = string

export type Transition = {
	name: string,
	from: State | { State },
	to: State | { State }
}

export type StateMachineDefinition = {
	states: { State },
	transitions: { Transition },
	initialState: State
}

export type TransitionHook = (State, State) -> any

function StateMachine.new(definition: StateMachineDefinition)
	if definition.states == nil or definition.transitions == nil or definition.initialState == nil then
		error("Invalid state machine definition")
	end

	for _, transition in pairs(definition.transitions) do
		if transition.name == "__start" or transition.name == "__all" then
			error(`Transition name {transition.name} is reserved`)
		end

		if typeof(transition.from) == "table" then
			local fromSet = {}

			for _, v in pairs(transition.from) do
				fromSet[v] = true
			end

			transition.from = fromSet
		end

		if typeof(transition.to) == "table" then
			local toSet = {}

			for _, v in pairs(transition.to) do
				toSet[v] = true
			end

			transition.to = toSet
		end
	end

	definition._transitionHooks = {}
	definition._transitioning = false

	return setmetatable(definition, StateMachine)
end

function StateMachine:_FindTransition(from: State, to: State)
	for _, v in pairs(self.transitions) do
		if
			((typeof(v.from) == "string" and v.from == from) or v.from[from])
			and ((typeof(v.to) == "string" and v.to == to) or v.to[to])
		then
			return v
		end
	end

	return nil
end

function StateMachine:Hook(transitionName: string, callback: TransitionHook)
	self._transitionHooks[transitionName] = callback
end

function StateMachine:Transition(state: State)
	if self._transitioning then
		error("Cannot transition during a transition")
	end

	if self._currentState == state then
		error("Cannot transition to the same state")
	end

	local transition = self:_FindTransition(self._currentState, state)

	if not transition then
		error(`No transition possible from {self._currentState} to {state}`)
	end

	self._transitioning = true

	local ok, err = pcall(function()
		local hookFunc = self._transitionHooks[transition.name] or function() end :: TransitionHook
		hookFunc(self._currentState, state)
		
		local hookFunc = self._transitionHooks["__all"] or function() end :: TransitionHook
		hookFunc(self._currentState, state)
	end)

	self._transitioning = false

	if not ok then
		error(`Transition from {self._currentState} to {state} failed: {err}`)
	end

	self._currentState = state
end

function StateMachine:Start()
	self._transitioning = true

	local hookFunc = self._transitionHooks.__start or function() end :: TransitionHook
	hookFunc(nil, self.initialState)

	self._transitioning = false

	self._currentState = self.initialState
end


return StateMachine