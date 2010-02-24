module Locomotive

module RubyAst

# Boxed Type
class BoxedType; end

# Row Type
# Represents a table row
class Row < BoxedType; end

# Table Type
# Represents a table, e.g. for a list representation
class Table < BoxedType; end

end

end
