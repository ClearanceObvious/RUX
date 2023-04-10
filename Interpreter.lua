local interpreter = {}
local mt = {__index = interpreter}

local base_ret_value = -90192309172412093192315671991789273981751072390
local base_skip_value = 200013309172412093192415671991189273900051072390

local FF_EXIT_LOOP = false

local console = require(script.Parent.Console)

local node = require(script.Parent.Node)
local nt = node.NodeType
local tt = require(script.Parent.Tokens)

function match(t1, t2)
	if type(t2) == 'table' then
		for i, v in pairs(t2) do
			if t1 == v then
				return true
			end
		end
	end

	if t1 == t2 then return true end

	return false
end

function getType(val)
	local check1 = tonumber(val)
	if check1 ~= nil then return nt.NUM end
	
	if typeof(val) == 'table' then
		local t = ''
		for i, v in pairs(val) do
			if typeof(v) == 'table' then break end
			return nt.STR
		end
		return nt.OBJ
	end
end

function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

function inSymbolTable(var, st)
	for i, v in pairs(st) do
		if i == var then
			return true
		end
	end
	
	return false
end


function interpreter.new(nodes)
	local self = setmetatable({}, mt)
	self.nodes = nodes
	self.symbolTable = {}
	
	--LOG
	self.symbolTable['log'] = {
		ARGS = {"message"},
		FUNCTION = function(message)
			-----
			local f
			if message.type then
				if message.type == nt.CFUNC then
					f = self.symbolTable['message']
				else
					f = self:visitExpression(message)
				end
			else
				f = if typeof(message) == 'table' then self:visitExpression(message) else self:visitVariableAccessNode(message).value
			end
			f = if f == base_ret_value then 'null' else f
			----
			
			console:pushToConsole(f)
		end,
	}
	
	--SLEEP
	self.symbolTable['sleep'] = {
		ARGS = {"timeToSleep"},
		FUNCTION = function(timeToSleep)
			-----
			local f
			if timeToSleep.type then
				if timeToSleep.type == nt.CFUNC then
					f = self.symbolTable['timeToSleep']
				else
					f = self:visitExpression(timeToSleep)
				end
			else
				f = if typeof(timeToSleep) == 'table' then self:visitExpression(timeToSleep) else self:visitVariableAccessNode(timeToSleep).value
			end
			f = if f == base_ret_value then 'null' else f
			----
			
			task.wait(f)
		end,
	}
	
	--RANDOM
	self.symbolTable['random'] = {
		ARGS = {'reference', 'num1', 'num2'},
		FUNCTION = function(reference, num1, num2)
			-----
			local n1
			if num1.type then
				if num1.type == nt.CFUNC then
					n1 = self.symbolTable['num1']
				else
					n1 = self:visitExpression(num1)
				end
			else
				n1 = if typeof(num1) == 'table' then self:visitExpression(num1) else self:visitVariableAccessNode(num1).value
			end
			n1 = if n1 == base_ret_value then 'null' else n1
			----
			-----
			local n2
			if num2.type then
				if num2.type == nt.CFUNC then
					n2 = self.symbolTable['num2']
				else
					n2 = self:visitExpression(num2)
				end
			else
				n2 = if typeof(num2) == 'table' then self:visitExpression(num2) else self:visitVariableAccessNode(num2).value
			end
			n2 = if n2 == base_ret_value then 'null' else n2
			----
			
			self:visitVariableOverrideNode(node.new(nt.VON, reference.value, node.new(nt.NUM, nil, math.random(n1, n2))))
		end,
	}
	
	self.fCurrentStack = {
		FUNC = {},
		LOOP = {}
	}
	
	return self
end

function interpreter:visitUnaryOp(type, value, op)
	if type == nt.NUM then
		local nod
		if typeof(value) == 'table' then
			nod = node.new(nt.NUM, nil, if op == tt.PLUS then value.value else value.value * -1)
		else
			nod = node.new(nt.NUM, nil, if op == tt.PLUS then value else value * -1)
		end
		return nod
	elseif type == nt.UNOP then
		local node = self:visitUnaryOp(value.type, value.value or value, value.op)
		return node
	elseif type == nt.BINOP then
		local binop = self:visitBinOp(value.left, value.op, value.right)
		return node.new(nt.NUM, nil, if op == tt.PLUS then binop.value else binop.value * -1)
	elseif type == nt.VAN then
		local van = self:visitVariableAccessNode(value)
		return node.new(nt.NUM, nil, if op == tt.PLUS then van.value else van.value * -1)
	elseif type == nt.CFUNC then
		local cfunc = self:callFunction(node.new(nt.CFUNC, op, value))
		return node.new(nt.NUM, nil, if op == tt.PLUS then cfunc.value else cfunc.value * -1)
	else
		error('Unknown Error In INTERPRETER:visitUnaryOp')
	end
end

function interpreter:visitVariableAccessNode(nod)
	if not (typeof(nod) == 'table') then
		local n = nod
		nod = {value = n}
	end
	
	if (typeof(nod.value) == 'table') then
		local str = ''
		for i, v in pairs(nod.value) do
			str = str .. v
		end
		nod.value = str
	end
	if not inSymbolTable(nod.value, self.symbolTable) then
		print('SYMBOL', self.symbolTable)
		error('Variable "' .. nod.value .. '" does not exist')
	end

	
	local check = tonumber(self.symbolTable[nod.value])
	local check2 = false
	
	if check then
		return node.new(nt.NUM, nil, self.symbolTable[nod.value])
	else
		if typeof(self.symbolTable[nod.value]) == 'table' then
			local str = ''
			for i, v in pairs(self.symbolTable[nod.value]) do
				if typeof(v) == 'table' then
					check2 = true
					break
				end
				str = str .. v
			end
			if check2 then
				local obj = self.symbolTable[nod.value]
				
				if nod.op.op ~= nil then
					local index = nod.op.op
					local index_as_val = self:visitExpression(index)
					local getval = self:visitExpression(obj[index_as_val])
					if typeof(getval) == 'table' then
						getval = self:visitExpression(getval)
					end
					return node.new(getType(getval), nil, getval)
				else
					local path = {}
					local curobj = obj
					for i, v in pairs(nod.op) do
						path[#path + 1] = self:visitExpression(v.op)
						curobj = curobj[path[#path]].value
					end
					
					return node.new(getType(curobj), nil, curobj)
				end
			end
			return node.new(nt.STR, nil, str)
		end
		return node.new(nt.STR, nil, self.symbolTable[nod.value])
	end
end

function interpreter:visitVariableOverrideNode(node)
	return self:visitVariableCreateNode(node, true)
end

function interpreter:visitVariableCreateNode(node, override: boolean?)
	if node.optional then
		node.optional = self:visitExpression(node.optional)
		if node.optional.type == nt.OBJACC then
			node.optional = self:visitExpression(node.optional.op)
		end
	end
	if not inSymbolTable(node.op, self.symbolTable) then
		local val = self:visitExpression(node.value)
		if not node.optional then
			self.symbolTable[tostring(node.op)] = val
		else
			self.symbolTable[tostring(node.op)][node.optional] = val
		end
	else
		if override then
			local val = self:visitExpression(node.value)
			local comp = node.left
			if comp then
				if comp == tt.CPLUS then
					if not node.optional then
						self.symbolTable[tostring(node.op)] += val
					else
						self.symbolTable[tostring(node.op)][node.optional] -= val
					end
				elseif comp == tt.CMIN then
					if not node.optional then
						self.symbolTable[tostring(node.op)] -= val
					else
						self.symbolTable[tostring(node.op)][node.optional] -= val
					end
				elseif comp == tt.CMUL then
					if not node.optional then
						self.symbolTable[tostring(node.op)] *= val
					else
						self.symbolTable[tostring(node.op)][node.optional] *= val
					end
				elseif comp == tt.CDIV then
					if not node.optional then
						self.symbolTable[tostring(node.op)] /= val
					else
						self.symbolTable[tostring(node.op)][node.optional] /= val
					end
				end
			else
				if not node.optional then
					self.symbolTable[tostring(node.op)] = val
				else
					self.symbolTable[tostring(node.op)][node.optional] = val
				end
			end
		else
			error('Variable ' .. node.op .. ' already exists')
		end
	end
end

function interpreter:visitBinOp(left, op, right)
	if left.type == nt.BINOP then
		left = self:visitBinOp(left.left, left.op, left.right)
	elseif left.type == nt.UNOP then
		left = self:visitUnaryOp(left.value.type, left.value, left.op)
	elseif left.type == nt.VAN then
		left = self:visitVariableAccessNode(left)
	elseif left.type == nt.CFUNC then
		local expr = self:visitExpression(self:callFunction(left))
		local check = tonumber(expr)
		if check then
			left = {type = nt.NUM, value = check}
		else
			if tostring(expr) == 'true' or tostring(expr) == 'false' then
				error('Cannot add Booleans Together')
			else
				left = {type = nt.STR, value = tostring(expr)}
			end
		end
	end
	
	if right.type == nt.BINOP then
		right = self:visitBinOp(right.left, right.op, right.right)
	elseif right.type == nt.UNOP then
		right = self:visitUnaryOp(right.value.type, right.value, right.op)
	elseif right.type == nt.VAN then
		right = self:visitVariableAccessNode(right)
	elseif right.type == nt.CFUNC then
		local expr = self:visitExpression(self:callFunction(right))
		local check = tonumber(expr)
		if check then
			right = {type = nt.NUM, value = check}
		else
			if tostring(expr) == 'true' or tostring(expr) == 'false' then
				error('Cannot add Booleans Together')
			else
				right = {type = nt.STR, value = tostring(expr)}
			end
		end
	end
	
	--String Concatenation
	if left.type == nt.STR and right.type == nt.STR then
		if op ~= tt.PLUS then
			error('Cannot perform operation ' .. op .. ' on strings.')
		end
		local str = ''
		if typeof(left.value) == 'table' then
			for _, val in ipairs(left.value) do
				str = str .. val
			end
		else
			str = str .. left.value
		end
		
		if typeof(right.value) == 'table' then
			for _, val in ipairs(right.value) do
				str = str .. val
			end
		else
			str = str .. right.value
		end
		return node.new(nt.STR, nil, str)
	end
	
	--Number Adding
	if left.type == nt.NUM and right.type == nt.NUM then
		if op == tt.PLUS then
			return node.new(nt.NUM, nil, left.value + right.value)
		elseif op == tt.MINUS then
			return node.new(nt.NUM, nil, left.value - right.value)
		elseif op == tt.MUL then
			return node.new(nt.NUM, nil, left.value * right.value)
		elseif op == tt.DIV then
			if right.value ~= 0 then
				return node.new(nt.NUM, nil, left.value / right.value)
			else
				error('Cannot Divide by 0')
			end
		end
	else
		error('Cannot add ' .. left.type .. ' with ' .. right.type)
	end
end

function interpreter:visitFCString(node)
	if node.type == nt.STR then
		local vals = node.value
		local str = ''
		
		for i, v in pairs(vals) do
			str = str .. v
		end
		return str
	else
		error('Unwanted Type')
	end
end

function interpreter:visitExpression(node)
	if node == nil then
		return nil
	end
	if node.type == nt.NUM or node.type == nt.STR or node.type == nt.BOOL then
		return node.value
	elseif node.type == nt.OBJ then
		return table.clone(node.value)
	elseif node.type == nt.UNOP then
		return self:visitUnaryOp(node.type, node.value, node.op).value
	elseif node.type == nt.BINOP then
		return self:visitBinOp(node.left, node.op, node.right).value
	elseif node.type == nt.VAN then
		return self:visitVariableAccessNode(node).value
	elseif node.type == nt.CFUNC then
		return self:visitExpression(self:callFunction(node))
	elseif node.type == nt.RETF then
		return self:visitExpression(node.value)
	elseif node.type == nt.COND then
		return self:visitConditionNode(node)
	else
		return node
	end
end

function interpreter:visitConditionalOperatorNode(cond)
	local left, right
	if cond.left.type == nt.NUM or cond.left.type == nt.STR or cond.left.type == nt.BOOL then
		left = cond.left.value
	elseif cond.left.type == nt.VAN then
		left = self:visitVariableAccessNode(cond.left).value
	elseif cond.left.type == nt.UNOP then
		left = self:visitUnaryOp(cond.left.value.type, cond.left.value, cond.left.op).value
	elseif cond.left.type == nt.BINOP then
		left = self:visitBinOp(cond.left.left, cond.left.op, cond.left.right).value
	elseif cond.left.type == nt.COND then
		left = self:visitConditionNode(cond.left)
	elseif cond.left.type == nt.CFUNC then
		left = self:visitExpression(self:callFunction(cond.left))
	elseif match(cond.left.type, {nt.EEQ, nt.NEEQ, nt.LT, nt.LTE, nt.GT, nt.GTE}) then
		left = self:visitConditionalOperatorNode(cond.left)
	else
		error('Unknown Type in If Statement ' .. cond.left.type)
	end
	
	if cond.right then
		if cond.right.type == nt.NUM or cond.right.type == nt.STR or cond.right.type == nt.BOOL then
			right = cond.right.value
		elseif cond.right.type == nt.VAN then
			right = self:visitVariableAccessNode(cond.right).value
		elseif cond.right.type == nt.UNOP then
			right = self:visitUnaryOp(cond.right.value.type, cond.right.value, cond.right.op).value
		elseif cond.right.type == nt.BINOP then
			right = self:visitBinOp(cond.right.left, cond.right.op, cond.right.right).value
		elseif cond.right.type == nt.COND then
			right = self:visitConditionNode(cond.right)
		elseif cond.right.type == nt.CFUNC then
			right = self:visitExpression(self:callFunction(cond.right))
		elseif match(cond.right.type, {nt.EEQ, nt.NEEQ, nt.LT, nt.LTE, nt.GT, nt.GTE}) then
			right = self:visitConditionalOperatorNode(cond.right)
		else
			error('Unknown Type in If Statement' .. cond.right.type)
		end
	else
		right = true
	end

	--If any of them are pure strings, we outstring the strings
	local s1 = ''
	local s2 = ''
	if typeof(left) == 'table' then
		for i, v in ipairs(left) do
			s1 = s1 .. v
		end
	else
		s1 = left
	end
	if typeof(right) == 'table' then
		for i, v in ipairs(right) do
			s2 = s2 .. v
		end
	else
		s2 = right
	end
	left = s1
	right = s2

	if cond.type == nt.EEQ then
		if left == right then
			return true
		else
			return false
		end
	elseif cond.type == nt.NEEQ then
		if left ~= right then
			return true
		else
			return false
		end
	elseif cond.type == nt.LT then
		if left < right then
			return true
		else
			return false
		end
	elseif cond.type == nt.LTE then
		if left <= right then
			return true
		else
			return false
		end
	elseif cond.type == nt.GT then
		if left > right then
			return true
		else
			return false
		end
	elseif cond.type == nt.GTE then
		if left >= right then
			return true
		else
			return false
		end
	elseif cond.type == nt.COND then
		return self:visitConditionNode(cond)
	else
		error('Invalid Condition ' .. dump(cond))
	end
end

function interpreter:visitConditionNode(node)
	local left = node.left
	local op = node.op
	local right = node.right
	
	local condition
	
	if op and right then
		left = self:visitConditionNode(left)
		if right.type == nt.COND then
			right = self:visitConditionNode(right)
		else
			right = self:visitConditionalOperatorNode(right)
		end
		if op.type == tt.OR then
			if left or right then
				condition = true
			else
				condition = false
			end
		elseif op.type == tt.AND then
			if left and right then
				condition = true
			else
				condition = false
			end
		else
			error('Invalid Operator If Statement')
		end
	else
		condition = self:visitConditionalOperatorNode(left)
	end
	
	return condition
end


function interpreter:ifStatement(node)
	local op = self:visitConditionNode(node.op)
	if op == true then
		return self:visitBlock(node.value)
	else
		if node.left then
			return self:ifStatement(node.left)
		end
	end
end

function interpreter:defineFunction(node)
	if inSymbolTable(node.value, self.symbolTable) then
		error('"'..node.value..'" already exists')
	end
	local ret = nil
	self.symbolTable[node.value] = {
		FUNCTION = function(...)
			local index = #self.fCurrentStack.FUNC+1
			self.fCurrentStack.FUNC[index] = node.value
		
			if #node.op ~= (#{...}) then
				error('Invalid number of arguments')
			end
			local block =  self:visitBlock(node.left)
			self.fCurrentStack.FUNC[index] = nil
		end,
		ARGS = node.op
	}
end

function interpreter:updateSymbolTable(args, val)
	for i, v in pairs(val) do
		local nod = node.new(nt.NUM, args[i], if inSymbolTable(v, self.symbolTable) then self:visitVariableAccessNode(v) else v)
		self:visitVariableOverrideNode(nod)
	end
end
function interpreter:differentiateSymbolTables(symb1: {}, symb2: {})
	local newSymb1 = symb1
	for i, v in symb2 do
		if inSymbolTable(i, symb1) then newSymb1[i] = v end
	end
	return newSymb1
end

function interpreter:callFunction(node)
	local lastSymbolTable
	if not inSymbolTable(node.value, self.symbolTable) then
		error('"'..node.value..'" doesnt exist.')
	end
	
	local args = self.symbolTable[node.value].ARGS
	if #args ~= #node.op then
		error('Function ' .. node.value .. ': Invalid Number of Arguments ' .. tostring(#args) .. ' : ' .. tostring(#node.op))
	end
	lastSymbolTable = deepcopy(self.symbolTable)
	self:updateSymbolTable(args, node.op)
	
	self.symbolTable[node.value].FUNCTION(unpack(node.op))
	local retTry = self.symbolTable[node.value].RET
	local returnVal = base_ret_value
	if retTry then
		returnVal = retTry
	end
	if typeof(returnVal) == 'table' then
		local t = ''
		for i, v in pairs(returnVal) do
			t = t .. v
		end
		returnVal = t
	end
	local st = self.symbolTable
	self.symbolTable = self:differentiateSymbolTables(lastSymbolTable, st)
	local retType = nil
	if typeof(returnVal) == 'boolean' then
		retType = nt.BOOL
	elseif typeof(returnVal) == 'string' then
		retType = nt.STR
	elseif typeof(returnVal) == 'number' then
		retType = nt.NUM
	end
	
	if retType then
		return node.new(retType, nil, returnVal)
	else
		return node.new(nt.NUM, nil, base_ret_value)
	end
end

function interpreter:forLoop(node)
	local lastSymbolTableFull = deepcopy(self.symbolTable)
	local lst
	self:visitVariableCreateNode(node.op)
	local __checkcondition = function()
		return self:visitConditionNode(node.value)
	end
	local __statementcall = function()
		self:visitVariableOverrideNode(node.left)
	end
	local block_to_visit = node.right
	
	local currentIndex = #self.fCurrentStack.LOOP + 1
	self.fCurrentStack.LOOP[currentIndex] = currentIndex
	
	while true do
		--Running the Loop
		lst = deepcopy(self.symbolTable)
		self:visitBlock(block_to_visit)
		if self.fCurrentStack.LOOP[currentIndex] == nil then FF_EXIT_LOOP = false; break end
		self.symbolTable = self:differentiateSymbolTables(lst, self.symbolTable)
		
		--For Loop Checks
		__statementcall()
		if not __checkcondition() then break end
	end
	
	self.fCurrentStack.LOOP[currentIndex] = nil
	
	self.symbolTable = self:differentiateSymbolTables(lastSymbolTableFull, self.symbolTable)
end

function interpreter:whileLoop(node)
	local lstFull = deepcopy(self.symbolTable)
	local lst
	local __checkcondition = function()
		return self:visitConditionNode(node.op)
	end
	local __visitBlock = function()
		self:visitBlock(node.value)
	end
	
	local currentIndex = #self.fCurrentStack.LOOP + 1
	self.fCurrentStack.LOOP[currentIndex] = currentIndex
	
	while true do
		--Running the Loop
		lst = deepcopy(self.symbolTable)
		__visitBlock()
		if self.fCurrentStack.LOOP[currentIndex] == nil then FF_EXIT_LOOP = false; break end
		self.symbolTable = self:differentiateSymbolTables(lst, self.symbolTable)
		
		--While Loop Checks
		if not __checkcondition() then break end
	end
	
	self.fCurrentStack.LOOP[currentIndex] = nil
	
	self.symbolTable = self:differentiateSymbolTables(lstFull, self.symbolTable)
end

function interpreter:visitStatement(node)
	if node.type == nt.VCN then
		--Creating Variables
		return self:visitVariableCreateNode(node)
	elseif node.type == nt.VON then
		--Overwriting Variables
		return self:visitVariableOverrideNode(node)
	elseif node.type == nt.IFN then
		--If statements
		return self:ifStatement(node)
	elseif node.type == nt.FORL then
		--For Loops
		self:forLoop(node)
	elseif node.type == nt.WHLN then
		--While loops
		self:whileLoop(node)
	elseif node.type == nt.FUNC then
		--Function declarations
		return self:defineFunction(node)
	elseif node.type == nt.CFUNC then
		--Function Calls
		return self:callFunction(node)
	elseif node.type == nt.RETF then
		--Return Statements
		if self.fCurrentStack.FUNC == {} then error('No Function') end
		self.symbolTable[self.fCurrentStack.FUNC[#self.fCurrentStack.FUNC]]["RET"] = self:visitExpression(node.value)
	elseif node.type == nt.BREAK then
		--Break Statements
		if self.fCurrentStack.LOOP == {} then error('No Loop') end
		FF_EXIT_LOOP = true
	end
end

function interpreter:visitBlock(block)
	for i, node in pairs(block) do
		--If Should Skip
		if self.fCurrentStack then
			if #self.fCurrentStack.FUNC > 0 and self.symbolTable[self.fCurrentStack.FUNC[#self.fCurrentStack.FUNC]].RET and #self.fCurrentStack.LOOP == 0 then
				return end
			if #self.fCurrentStack.LOOP > 0 and FF_EXIT_LOOP then
				self.fCurrentStack.LOOP[#self.fCurrentStack.LOOP] = nil
				return
			end
		end
		local v = self:visitStatement(node)
	end
end

function interpreter:interpret()
	self:visitBlock(self.nodes)
end
return interpreter
