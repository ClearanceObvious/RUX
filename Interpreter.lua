local interpreter = {}
local mt = {__index = interpreter}

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
	self.symbolTable = {
		log = {
			ARGS = {"message"},
			FUNCTION = function(message)
				local mes = if typeof(message) == 'table' then self:visitExpression(message) else self:visitVariableAccessNode(message).value
				if typeof(mes) == 'table' then
					local t = ''
					for i, v in pairs(mes) do
						t = t .. v
					end
					mes = t
				end
				print(mes)
			end,
		}
	}
	self.localSymbolTables = {}
	
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
		print(self.symbolTable)
		error('Variable "' .. nod.value .. '" does not exist')
	end

	
	local check = tonumber(self.symbolTable[nod.value])
	
	if check then
		return node.new(nt.NUM, nil, self.symbolTable[nod.value])
	else
		if typeof(self.symbolTable[nod.value]) == 'table' then
			local str = ''
			for i, v in pairs(self.symbolTable[nod.value]) do
				str = str .. v
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
	if not inSymbolTable(node.op, self.symbolTable) then
		local val = self:visitExpression(node.value)
		self.symbolTable[tostring(node.op)] = val
	else
		if override then
			local val = self:visitExpression(node.value)
			self.symbolTable[tostring(node.op)] = val
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
	else
		error('Unknown Error in Expression')
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
		self:visitBlock(node.value)
	else
		if node.left then
			self:ifStatement(node.left)
		end
	end
end

function interpreter:defineFunction(node)
	if inSymbolTable(node.value, self.symbolTable) then
		error('"'..node.value..'" already exists')
	end
	
	if not node.right then
		self.symbolTable[node.value] = {
			FUNCTION = function(...)
				if #node.op ~= (#{...}) then
					error('Invalid number of arguments')
				end
				self:visitBlock(node.left)
			end,
			ARGS = node.op
		}
	else
		self.symbolTable[node.value] = {
			FUNCTION = function(...)
				if #node.op ~= (#{...}) then
					error('Invalid number of arguments')
				end
				self:visitBlock(node.left)
			end,
			ARGS = node.op,
			RET = node.right
		}
	end
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
	local returnVal = if retTry then self:visitExpression(retTry) else nil
	if retTry then
		if retTry.value.type == nt.STR then
			returnVal = self:visitFCString(retTry.value)
		end
	end
	
	
	
	self.symbolTable = self:differentiateSymbolTables(lastSymbolTable, self.symbolTable)
	
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
		return node.new(nt.NUM, nil, 0)
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
	
	while true do
		--Running the Loop
		lst = deepcopy(self.symbolTable)
		local ret = self:visitBlock(block_to_visit)
		self.symbolTable = self:differentiateSymbolTables(lst, self.symbolTable)
		if ret then break end
		
		--For Loop Checks
		__statementcall()
		if not __checkcondition() then break end
	end
	
	self.symbolTable = self:differentiateSymbolTables(lastSymbolTableFull, self.symbolTable)
end

function interpreter:whileLoop(node)
	local lstFull = deepcopy(self.symbolTable)
	local lst
	local __checkcondition = function()
		return self:visitConditionNode(node.op)
	end
	local __visitBlock = function()
		return self:visitBlock(node.value)
	end
	
	while true do
		--Running the Loop
		lst = deepcopy(self.symbolTable)
		if __visitBlock() then break end
		self.symbolTable = self:differentiateSymbolTables(lst, self.symbolTable)
		
		--While Loop Checks
		if not __checkcondition() then break end
	end
	
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
		self:ifStatement(node)
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
	end
end

function interpreter:visitBlock(block)
	for i, node in pairs(block) do
		if node.type == nt.BREAK then return true end
		self:visitStatement(node)
	end
end

function interpreter:interpret()
	self:visitBlock(self.nodes)
end

return interpreter
