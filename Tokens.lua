local tokens = {}

tokens.PLUS = 'PLUS'
tokens.MINUS = 'MINUS'
tokens.MUL = 'MUL'
tokens.DIV = 'DIV'

tokens.EQ = 'EQUALS'

tokens.EEQ = 'DOUBLEEQUALS'
tokens.NEEQ = 'NOTDOUBLEEQUALS'

tokens.LT = 'LESSTHAN'
tokens.GT = 'GREATERTHAN'

tokens.LTE = 'LESSTHANOREQUAL'
tokens.GTE = 'GREATERTHANOREQUAL'

tokens.AND = 'IFSTATEMENTAND'
tokens.OR = 'IFSTATEMENTOR'

tokens.STR = 'STRING'
tokens.NUM = 'NUM'

tokens.LSTR = 'LEFTSTRING'
tokens.RSTR = 'RIGHTSTRING'

tokens.LP = 'LEFT_PARENTHESES'
tokens.RP = 'RIGHT_PARENTHESES'
tokens.LCB = 'LEFT_CURLYBRACKETS'
tokens.RCB = 'RIGHT_CURLYBRACKETS'

tokens.AID = 'ACCESSID'

tokens.KW = 'KEYWORD'
tokens.ID = 'IDENTIFIER'

tokens.EOL = 'ENDOFLINE'	--";"

return tokens
