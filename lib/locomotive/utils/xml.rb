module Locomotive

module XML

def self.included(klass)
  klass.extend ClassMethods
end

module ClassMethods

  def def_node(*mtds)
    mtds.each do |mtd|
      define_method(mtd) do |attrs={},&block|
        attr_list = []
        attrs.keys.each do |attr|
          attr_list << "#{attr}=#{quote(attrs[attr])}"
        end
        mtd_name = mtd.to_s
        if /^_?(?<name>[a-z]*)_?$/i =~ mtd_name.to_s
          mtd_name = name
        end
        xml = "<#{mtd_name}"
        xml += " " unless attr_list.empty?
        if block.nil?
          xml += "#{attr_list.join(" ")}/>\n"
        else
          content = block.call.to_s
          xml += "#{attr_list.join(" ")}>#{content.length < 60 ? "" : "\n"}" \
          "#{content}#{content.length < 60 ? "" : "\n"}" \
          "</#{mtd_name}>\n"
        end
      end
    end
  end
end

def quote(val)
  "\"#{val}\""
end

def to_xml
  "#{self.class.to_s.split("::").last.downcase}".to_sym
end

end

end
