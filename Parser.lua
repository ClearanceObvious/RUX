local parser = {}
local mt = {__index = parser}

local tt = require(script.Parent.Tokens)

local node = require(script.Parent.Node)
local nt = node.NodeType

local keywords = require(script.Parent.Lexer).keywords

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

--[[

TOKEN
	type, value		-> Token.type || Token.value

]]

local operators = {tt.PLUS, tt.MINUS, tt.MUL, tt.DIV}

function parser.new(tokens)
	local self = setmetatable({}, mt)
	self.tokens = tokens
	self.currentNum = 1
	self.currentToken = self.tokens[self.currentNum]
	
	return self
end

function parser:advance()
	self.currentNum += 1
	self.currentToken = self.tokens[self.currentNum] or nil
end


function parser:factor()
	local ret = nil
	
	if not pcall(function()
		if self.currentToken.type == tt.AID then
			self:advance()
			ret = node.new(nt.VAN, nil, self.currentToken.value)
			self:advance()
		elseif self.currentToken.type == tt.LSTR then
			ret = self:get_string()
		elseif self.currentToken.type == tt.LP then
			self:advance()
			ret = self:expression(true)
			self:advance()
		elseif self.currentToken.type == tt.MINUS or self.currentToken.type == tt.PLUS then
			local op = self.currentToken.type
			self:advance()
			ret = node.new(nt.UNOP, op, self:factor())
		elseif self.currentToken.type == tt.NUM then
			local val = self.currentToken.value
			
			self:advance()
			ret = node.new(nt.NUM, nil, val)
		else
			error('Number expected, got ' .. if self.currentToken then self.currentToken.type:lower() else 'nothing')
		end
	end) then print(dump(self.currentToken)); error('Invalid Syntax Error Occured!') end
	
	return ret
end

function parser:term(first: boolean?)
	local left = self:factor(first)
	
	while self.currentToken ~= nil and self.currentNum <= #self.tokens and match(self.currentToken.type, {tt.MUL, tt.DIV}) do
		local op = self.currentToken.type
		self:advance()
		
		left = node.new(nt.BINOP, op, nil, left, self:factor(false))
	end
	
	return left
end


function parser:get_string(optional_van: any?)
	self:advance()
	if self.currentToken.type ~= tt.STR then error('Expected String') end
	local strVal = if not optional_van then {self.currentToken.value} else {optional_van, self.currentToken.value}
	self:advance()
	if self.currentToken.type ~= tt.RSTR then error('Expected "') end
	self:advance()

	return node.new(nt.STR, nil, strVal)
end

function parser:assign_variable(id)
	if self.currentToken.type == tt.EQ then
		self:advance()
		local expr = self:expression()
		if self.currentToken then
			if self.currentToken.type ~= tt.EOL then
				error('Unfinished Statement')
			end
		else
			error('Unfinished Statement')
		end
		self:advance()
		return node.new(nt.VCN, id, expr)
	else
		error('Expected Equals "="')
	end
end

function parser:expression(expect_brackets)
	local left = self:term(true)
	
	while self.currentToken ~= nil and self.currentNum <= #self.tokens and match(self.currentToken.type, {tt.PLUS, tt.MINUS}) do
		local op = self.currentToken.type
		self:advance()

		left = node.new(nt.BINOP, op, nil, left, self:term(false))
	end
	if expect_brackets then
		if self.currentToken then
			if self.currentToken.type ~= tt.RP then
				error('Unknown Syntax Error Occured')
			end
		end
	end

	return left
end

function parser:condition_expression(did_lp :boolean?)
	if self.currentToken.type == tt.LP and not did_lp then
		return self:if_condition(true)
	end
	local left = self:expression()
	local condition = self.currentToken.type
	self:advance()
	local right =  self:expression()
	local nod
	if condition == tt.EEQ then
		nod = node.new(nt.EEQ, nil, nil, left, right)
	elseif condition == tt.NEEQ then
		nod = node.new(nt.NEEQ, nil, nil, left, right)
	elseif condition == tt.LT then
		nod = node.new(nt.LT, nil, nil, left, right)
	elseif condition == tt.LTE then
		nod = node.new(nt.LTE, nil, nil, left, right)
	elseif condition == tt.GT then
		nod = node.new(nt.GT, nil, nil, left, right)
	elseif condition == tt.GTE then
		nod = node.new(nt.GTE, nil, nil, left, right)
	else
		error('Expected Conditional Operator')
	end
	
	return nod
end

function parser:if_condition(did_lp: boolean?)
	self:advance()
	local cond = self:condition_expression(did_lp)
	local left = node.new(nt.COND, nil, nil, cond)

	while self.currentToken.type == tt.AND or self.currentToken.type == tt.OR  do
		local tok = self.currentToken
		self:advance()
		left = node.new(nt.COND, tok, nil, left, self:condition_expression())
	end
	
	if did_lp then self:advance() end
	
	return left
end

function parser:if_statement()
	local left = self:if_condition()
	local elifs = nil
	
	if self.currentToken.type ~= tt.RP then error('Expected Right Parentheses') end
	self:advance()
	if self.currentToken.type ~= tt.LCB then error('Expected "{"') end
	self:advance()
	
	local block = self:block(true)
	
	--Else && Elseif
	if self.currentToken then
		if self.currentToken.type == tt.KW and self.currentToken.value == keywords._else then
			self:advance()
			if self.currentToken.type == tt.KW and self.currentToken.value == keywords._if then
				self:advance()
				elifs = self:if_statement()
			elseif self.currentToken.type == tt.LCB then
				self:advance()
				elifs = node.new(
					nt.IFN,
					node.new(nt.COND, nil, nil, node.new(nt.EEQ, nil, nil, node.new(nt.NUM, nil, 0), node.new(nt.NUM, nil, 0))),
					self:block(true)
				)
			else
				error('Invalid Syntax After Else Occured')
			end
		end
	end
	
	return node.new(nt.IFN, left, block, elifs)
end

function parser:statement()
	if self.currentToken then
		if self.currentToken.type == tt.KW then
			local kw = self.currentToken.value
			self:advance()
			
			if kw == keywords.let and self.currentToken.type == tt.ID then
				--Variable Assignment
				local id = self.currentToken.value
				self:advance()
				return self:assign_variable(id)
			elseif kw == keywords._if and self.currentToken.type == tt.LP then
				--If Statement
				return self:if_statement()
			else
				error('Unfinished Statement')
			end
		elseif self.currentToken.type == tt.AID then
			self:advance()
			local val = self.currentToken.value
			self:advance()
			if self.currentToken then
				if self.currentToken.type == tt.EOL then
					self:advance()
				end
			end
			return node.new(nt.VAN, nil, val)
		else
			error('Expected Keyword')
		end
	else
		error('Unknown Error Finding Statement')
	end
end

function parser:block(expect_right_curly_brackets)
	local statements = {}
	if expect_right_curly_brackets then
		while self.currentToken ~= nil and self.currentToken.type ~= tt.RCB do
			statements[#statements+1] = self:statement()
		end
		if self.currentToken.type == tt.RCB then
			self:advance()
		else
			error('Expected "}"')
		end
	else
		while self.currentToken ~= nil do
			statements[#statements+1] = self:statement()
		end
	end
	
	return statements
end

function parser:parse()
	
	return self:block(false)
end

return parser
