local lexer = {}
local mt = {__index = lexer}

local tt = require(script.Parent.Tokens)

local lowercase = 'abcdefghijklmnopqrstuvwxyz'
local uppercase = lowercase:upper()
local strtable = lowercase .. uppercase .. ' !@#$%^&*()_+|{}:?></.,;[]-=\\0123456789'

lexer.keywords = {
	let = 'let',
	_if = 'if',
	_else = 'else',
	_for = 'for',
	_whl = 'while',
	_return = 'return',
	_break = 'break'
}

function isWhiteSpace(char)
	if char == ' ' or char == '\n' or char == '' or char == '\r' or char == '\t' then
		return true
	end
	return false
end

function charIn(char, text)
	for i = 1, text:len(), 1 do
		if char == text:sub(i, i) then return true end
	end
	return false
end

function strInTable(str, t: {})
	for i, v in pairs(t) do
		if str == v then
			return true
		end
	end

	return false
end

function lexer.new(input)
	local self = setmetatable({}, mt)
	self.text = input
	self.currentNum = 1
	self.currentChar = string.sub(self.text, self.currentNum, self.currentNum)

	return self
end

function lexer:advance()
	self.currentNum += 1
	self.currentChar = string.sub(self.text, self.currentNum, self.currentNum) or nil
end

function lexer:lex()
	local tokens = {}

	while self.currentChar ~= nil and self.currentNum <= string.len(self.text) do
		if isWhiteSpace(self.currentChar) then
			self:advance()
			continue
		elseif self.currentChar == '"' then
			tokens[#tokens+1] = {type = tt.LSTR}
			self:advance()
			tokens[#tokens+1] = self:getStr()
			if self.currentChar ~= '"' then
				print(self.currentChar)
				error('Expected "')
			end
			tokens[#tokens+1] = {type = tt.RSTR}
			self:advance()
		elseif self.currentChar == '!' then
			if self.text:sub(self.currentNum+1, self.currentNum+1) == '=' then
				tokens[#tokens+1] = {type = tt.NEEQ, value = nil}
				self:advance(); self:advance();
			else
				error('Expected Equals "="')
			end
		elseif self.currentChar == '&' then
			if self.text:sub(self.currentNum+1, self.currentNum+1) == '&' then
				tokens[#tokens+1] = {type = tt.AND, value = nil}
				self:advance(); self:advance();
			else
				error('Expected And "&"')
			end
		elseif self.currentChar == '|' then
			if self.text:sub(self.currentNum+1, self.currentNum+1) == '|' then
				tokens[#tokens+1] = {type = tt.OR, value = nil}
				self:advance(); self:advance();
			else
				error('Expected Or "|"')
			end
		elseif self.currentChar == '=' then
			if self.text:sub(self.currentNum+1, self.currentNum+1) == '=' then
				tokens[#tokens+1] = {type = tt.EEQ, value = nil}
				self:advance(); self:advance(); continue
			end
			tokens[#tokens+1] = {type = tt.EQ, value = nil}
			self:advance()
		elseif self.currentChar == '<' then
			if self.text:sub(self.currentNum+1, self.currentNum+1) == '=' then
				tokens[#tokens+1] = {type = tt.LTE, value = nil}
				self:advance(); self:advance(); continue
			end
			tokens[#tokens+1] = {type = tt.LT, value = nil}
			self:advance()
		elseif self.currentChar == '>' then
			if self.text:sub(self.currentNum+1, self.currentNum+1) == '=' then
				tokens[#tokens+1] = {type = tt.GTE, value = nil}
				self:advance(); self:advance(); continue
			end
			tokens[#tokens+1] = {type = tt.GT, value = nil}
			self:advance()
		elseif self.currentChar == '/' then
			if self.text:sub(self.currentNum+1, self.currentNum+1) == '/' then
				self:advance(); self:advance()
				tokens[#tokens+1] = {type = tt.COMMENT, value = self:getComment()}
				continue
			elseif self.text:sub(self.currentNum+1, self.currentNum+1) == '=' then
				self:advance(); self:advance()
				tokens[#tokens+1] = {type = tt.CDIV, value = nil}; continue
			end
			tokens[#tokens+1] = {type = tt.DIV, value = nil}
			self:advance()
		elseif self.currentChar == '+' then
			if self.text:sub(self.currentNum+1, self.currentNum+1) == '=' then
				self:advance(); self:advance()
				tokens[#tokens+1] = {type = tt.CPLUS, value = nil}; continue
			end
			tokens[#tokens+1] = {type = tt.PLUS, value = nil}
			self:advance()
		elseif self.currentChar == '-' then
			if self.text:sub(self.currentNum+1, self.currentNum+1) == '=' then
				self:advance(); self:advance()
				tokens[#tokens+1] = {type = tt.CMIN, value = nil}; continue
			end
			tokens[#tokens+1] = {type = tt.MINUS, value = nil}
			self:advance()
		elseif self.currentChar == '*' then
			if self.text:sub(self.currentNum+1, self.currentNum+1) == '=' then
				self:advance(); self:advance()
				tokens[#tokens+1] = {type = tt.CMUL, value = nil}; continue
			end
			tokens[#tokens+1] = {type = tt.MUL, value = nil}
			self:advance()
		elseif self.currentChar == '{' then
			tokens[#tokens+1] = {type = tt.LCB, value = nil}
			self:advance()
		elseif self.currentChar == '}' then
			tokens[#tokens+1] = {type = tt.RCB, value = nil}
			self:advance()
		elseif self.currentChar == '[' then
			tokens[#tokens+1] = {type = tt.LQP, value = nil}
			self:advance()
		elseif self.currentChar == ']' then
			tokens[#tokens+1] = {type = tt.RQP, value = nil}
			self:advance()
		elseif self.currentChar == ':' then
			tokens[#tokens+1] = {type = tt.COLON, value = nil}
			self:advance()
		elseif self.currentChar == ',' then
			tokens[#tokens+1] = {type = tt.COMMA, value = nil}
			self:advance()
		elseif self.currentChar == '(' then
			tokens[#tokens+1] = {type = tt.LP, value = nil}
			self:advance()
		elseif self.currentChar == ')' then
			tokens[#tokens+1] = {type = tt.RP, value = nil}
			self:advance()
		elseif self.currentChar == ';' then
			tokens[#tokens+1] = {type = tt.EOL, value = nil}
			self:advance()
		elseif self.currentChar == '$' then
			tokens[#tokens+1] = {type = tt.AID, value = nil}
			self:advance()
		elseif charIn(self.currentChar, '0123456789') then
			tokens[#tokens+1] = {type = tt.NUM, value = self:getNumber()}
		elseif charIn(self.currentChar, lowercase .. uppercase .. '_') then
			tokens[#tokens+1] = self:getID()
		else
			error('Unknown Character ' .. self.currentChar ..  ' Occured')
		end
	end

	return tokens
end

function lexer:getStr()
	local str = ''

	while charIn(self.currentChar, strtable) do
		str = str .. self.currentChar
		self:advance()
	end

	return {type = tt.STR, value = str}
end

function lexer:getID()
	local id = ''

	while charIn(self.currentChar, lowercase .. uppercase .. '_0123456789') do
		id = id .. self.currentChar
		self:advance()
	end

	if strInTable(id, self.keywords) then
		return {type = tt.KW, value = id}
	end

	if id == 'true' then
		return {type = tt.BOOL, value = true}
	elseif id == 'false' then
		return {type = tt.BOOL, value = false}
	else
		return {type = tt.ID, value = id}
	end
end

function lexer:getComment()
	local str = ''

	while charIn(self.currentChar, strtable) do
		str = str .. self.currentChar
		self:advance()
	end

	return str
end

function lexer:getNumber()
	local dots = 0
	local strNum = ''

	while charIn(self.currentChar, '0123456789.') do
		if self.currentChar == '.' then
			if dots >= 1 then
				strNum = strNum .. '.'
				error('Invalid Number : ' .. strNum)
			end
			dots += 1
			strNum = strNum .. '.'
			self:advance()
		else
			strNum = strNum .. self.currentChar
			self:advance()
		end
	end

	return tonumber(strNum)
end

return lexer
