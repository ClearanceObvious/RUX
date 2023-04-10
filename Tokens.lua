local tokens = {}

tokens.PLUS = 'PLUS'
tokens.MINUS = 'MINUS'
tokens.MUL = 'MUL'
tokens.DIV = 'DIV'

tokens.EQ = 'EQUALS'
tokens.COLON = 'COLON'

tokens.EEQ = 'DOUBLEEQUALS'
tokens.NEEQ = 'NOTDOUBLEEQUALS'

tokens.LT = 'LESSTHAN'
tokens.GT = 'GREATERTHAN'

tokens.COMMA = 'COMMA'

tokens.LTE = 'LESSTHANOREQUAL'
tokens.GTE = 'GREATERTHANOREQUAL'

tokens.CPLUS = 'COMPUNDPLUS'
tokens.CMIN = 'COMPUNDMINUS'
tokens.CMUL = 'COMPOUNDMUL'
tokens.CDIV = 'COMPOUNDDIV'

tokens.AND = 'IFSTATEMENTAND'
tokens.OR = 'IFSTATEMENTOR'

tokens.STR = 'STRING'
tokens.NUM = 'NUM'
tokens.BOOL = 'BOOLEAN'

tokens.LSTR = 'LEFTSTRING'
tokens.RSTR = 'RIGHTSTRING'

tokens.LP = 'LEFT_PARENTHESES'
tokens.RP = 'RIGHT_PARENTHESES'
tokens.LCB = 'LEFT_CURLYBRACKETS'
tokens.RCB = 'RIGHT_CURLYBRACKETS'
tokens.LQP = 'LEFT_SQUAREBRACKETS'
tokens.RQP = 'RIGHT_SQUAREBRACKETS'

tokens.AID = 'ACCESSID'
tokens.ID = 'IDENTIFIER'

tokens.KW = 'KEYWORD'

tokens.COMMENT = 'COMMENT'
tokens.EOL = 'ENDOFLINE'	--";"

return tokens
