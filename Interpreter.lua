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

--[[

NODETYPE:
	NUM, BINOP, UNOP

NODE: type, op, value, left, right
]]

function interpreter.new(nodes)
	local self = setmetatable({}, mt)
	self.nodes = nodes
	self.symbolTable = {}
	
	return self
end

--1 + -(1 - 3)
function interpreter:visitUnaryOp(type, value, op)
	if type == nt.NUM then
		local node = node.new(nt.NUM, nil, if op == tt.PLUS then value.value else value.value * -1)
		return node
	elseif type == nt.UNOP then
		local node = self:visitUnaryOp(value.type, value.value or value, value.op)
		return node
	elseif type == nt.BINOP then
		local binop = self:visitBinOp(value.left, value.op, value.right)
		return node.new(nt.NUM, op, if op == tt.PLUS then binop.value else binop.value * -1)
	else
		error('Unknown Error In INTERPRETER:visitUnaryOp')
	end
end

function interpreter:visitVariableAccessNode(node)
	if not inSymbolTable(node.value, self.symbolTable) then
		error('Variable ' .. node.value .. ' does not exist')
	end
	local check = tonumber(self.symbolTable[node.value])
	
	if check then
		return node.new(nt.NUM, nil, self.symbolTable[node.value])
	else
		if typeof(self.symbolTable[node.value]) == 'table' then
			local str = ''
			for i, v in pairs(self.symbolTable[node.value]) do
				str = str .. v
			end
			return node.new(nt.STR, nil, str)
		end
		return node.new(nt.STR, nil, self.symbolTable[node.value])
	end
end

function interpreter:visitVariableCreateNode(node)
	if not inSymbolTable(node.op, self.symbolTable) then
		self.symbolTable[tostring(node.op)] = self:visitExpression(node.value)
	else
		error('Variable ' .. node.op .. ' already exists')
	end
end

function interpreter:visitBinOp(left, op, right)
	if left.type == nt.BINOP then
		left = self:visitBinOp(left.left, left.op, left.right)
	elseif left.type == nt.UNOP then
		left = self:visitUnaryOp(left.value.type, left.value, left.op)
	elseif left.type == nt.VAN then
		left = self:visitVariableAccessNode(left)
	end
	
	if right.type == nt.BINOP then
		right = self:visitBinOp(right.left, right.op, right.right)
	elseif right.type == nt.UNOP then
		right = self:visitUnaryOp(right.value.type, right.value, right.op)
	elseif right.type == nt.VAN then
		right = self:visitVariableAccessNode(right)
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

function interpreter:visitExpression(node)
	if node.type == nt.NUM then
		return node.value
	elseif node.type == nt.STR then
		return node.value
	elseif node.type == nt.UNOP then
		return self:visitUnaryOp(node.type, node.value, node.op).value
	elseif node.type == nt.BINOP then
		return self:visitBinOp(node.left, node.op, node.right).value
	elseif node.type == nt.VAN then
		return self:visitVariableAccessNode(node).value
	else
		print(node.type, nt.STR)
		error('Unknown Error in Expression')
	end
end

function interpreter:visitConditionalOperatorNode(cond)
	local left, right
	if cond.left.type == nt.NUM or cond.left.type == nt.STR then
		left = cond.left.value
	elseif cond.left.type == nt.VAN then
		left = self:visitVariableAccessNode(cond.left).value
	elseif cond.left.type == nt.UNOP then
		left = self:visitUnaryOp(cond.left.value.type, cond.left.value, cond.left.op).value
	elseif cond.left.type == nt.BINOP then
		left = self:visitBinOp(cond.left.left, cond.left.op, cond.left.right).value
	elseif cond.left.type == nt.COND then
		left = self:visitConditionNode(cond.left)
	elseif match(cond.left.type, {nt.EEQ, nt.NEEQ, nt.LT, nt.LTE, nt.GT, nt.GTE}) then
		left = self:visitConditionalOperatorNode(cond.left)
	else
		error('Unknown Type in If Statement ' .. cond.left.type)
	end


	if cond.right.type == nt.NUM or cond.right.type == nt.STR then
		right = cond.right.value
	elseif cond.right.type == nt.VAN then
		right = self:visitVariableAccessNode(cond.right).value
	elseif cond.right.type == nt.UNOP then
		right = self:visitUnaryOp(cond.right.value.type, cond.right.value, cond.right.op).value
	elseif cond.right.type == nt.BINOP then
		right = self:visitBinOp(cond.right.left, cond.right.op, cond.right.right).value
	elseif cond.right.type == nt.COND then
		right = self:visitConditionNode(cond.right)
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

function interpreter:visitStatement(node)
	if node.type == nt.VCN then
		--Creating Variables
		self:visitVariableCreateNode(node)
	elseif node.type == nt.IFN then
		--If statements
		self:ifStatement(node)
	elseif node.type == nt.VAN then
		--For now we just print the value
		print(self:visitVariableAccessNode(node).value)
	end
end

function interpreter:visitBlock(block)
	for i, node in pairs(block) do
		self:visitStatement(node)
	end
end

function interpreter:interpret()
	self:visitBlock(self.nodes)
end

return interpreter
