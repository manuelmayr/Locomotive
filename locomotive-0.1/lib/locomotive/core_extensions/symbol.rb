module FerryCore

  module SymbolExtensions
    def classify
      Inflector::camelize(self).to_sym
    end

    Symbol.send :include, self
  end

end
