local node = {}
local mt = {__index = node}

node.NodeType = {
	NUM = 'NumberNode',				--type NUM, value float
	STR = 'StringNode',				--type STR, value string
	BOOL = 'BooleanNode',			--type BOOL, value false/true
	
	OBJ = 'ObjectNode'	,			--type OBJ, value expr*
	OBJACC = 'ObjectAccessNode',	--type OBJACC, op expr
	
	BINOP = 'BinaryOperationNode',	--type BINOP, left expr, right expr
	UNOP = 'UnaryOperationNode',	--type UNOP, op +/-, value expr
	
	EEQ = 'DoubleEqualNode',		--type EEQ, left expr, right expr
	NEEQ = 'NotDoubleEqualNode',	--type NEEQ, left expr, right expr
	
	LT = 'LessThenNode',			--type LE, left expr, right expr, op and/or?
	LTE = 'LessThenOrEqualNode',	--type LTE, left expr, right expr, op and/or?
	GT = 'GreaterThenNode',			--type GT, left expr, right expr, op and/or?
	GTE = 'GreaterThenOrEqualNode',	--type GTE, left expr, right expr, op and/or?
	
	COND = 'ConditionNode',			--type COND, op AND/OR?, left cond, right cond?
	IFN = 'IfStatementNode',		--type IFN, op COND, value block, left IFN?
	
	FUNC = 'FunctionNode',			--type FUNC, op args, value id, left block, right RETF?
	CFUNC = 'CallFunctionNode',		--type CFUNC, op args, value id
	RETF = 'ReturnFunctionNode',	--type RETF, value expr?
	
	FORL = 'ForLoopNode',			--type FORL, op VCN, value COND, left VON, right block
	WHLN = 'WhileLoopNode',			--type WHLN, op COND, value block
	BREAK = 'BreakLoopNode',		--type BREAK
	
	VCN = 'VariableCreateNode',		--type VCN, op ID, value expr
	VAN = 'VariableAccessNode',		--type VAN, value ID, op OBJACC?
	VON = 'VariableOverrideNode'	--type VON, op ID, value expr, left compound_operator?
}

function node.new(type, op: any?, value: any?, left: any?, right: any?, optional: any?)
	local self = setmetatable({}, mt)
	self.type = type
	self.value = value
	self.left = left
	self.right = right
	self.op = op
	self.optional = optional
	
	return self
end


return node
