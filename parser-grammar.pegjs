/*
 * Classic example grammar, which recognizes simple arithmetic expressions like
 * "2*(3+4)". The parser generated from this grammar then computes their value.
 */

start
  = additive

additive
  = left:multiplicative "+" right:additive { return left + right; }
  / left:multiplicative "-" right:additive { return left - right; }
  / multiplicative

multiplicative
  = left:primary "*" right:multiplicative { return left * right; }
  / left:primary "/" right:multiplicative { return left / right; }
  / primary

primary
  = decimal
  / integer
  / cell
  / "(" additive:additive ")" { return additive; }


integer "integer"
  = digits:[0-9]+ { return parseInt(digits.join(""), 10); }


decimal "decimal"
  = start: [0-9]+'.' end:[0-9]+ { return parseFloat (start.join("") + "." + end.join("")); }

cell
  = col: [a-zA-Z]+ row:[0-9]+ {return window.resolveCell(row.join(""),col.join(""))}

