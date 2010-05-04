module FerryCore

  module Inflector
    extend self

    def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
      str = lower_case_and_underscored_word.to_s
      if first_letter_in_uppercase then
        str.gsub(/\/(.?)/) { "::#{$1.upcase}" }.
            gsub(/(?:^|_)(.)/) { $1.upcase }
      else
        str[0].chr.downcase + 
               camelize(lower_case_and_underscored_word)[1..-1]
      end   
    end
  end

end
