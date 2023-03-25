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

tokens.AID = 'ACCESSID'
tokens.ID = 'IDENTIFIER'

tokens.KW = 'KEYWORD'

tokens.COMMENT = 'COMMENT'
tokens.EOL = 'ENDOFLINE'	--";"

return tokens
