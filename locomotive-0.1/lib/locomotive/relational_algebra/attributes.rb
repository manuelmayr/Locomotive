module Locomotive

  module RelationalAlgebra
  
    class Attribute
      protected
    
      def nth id
        if id == 0
          ""
        else
           id.to_s
        end
      end 
     
      public
     
      attr_reader :id
     
      def initialize(id=0)
        raise AbstractClassError,
              "#{self.class} is an abstract class" if self.class == Attribute
        self.id = id
      end
    
      # we only accept positive integers as ids
      def id=(id)
        raise IdError, "#{id} less than 0" if id < 0
        @id = id 
      end
      def_sig :id=, Fixnum
    
      def inc(val)
        self.id += val
      end
     
      def to_xml
        # Be careful of classes that are nested in modules
        "#{self.class.to_s.split("::").last.downcase}#{nth id}".to_sym
      end
    
      # Equality for attributes is defined over
      # their class and id
      def ==(other)
        self.class == other.class and
        self.id == other.id
      end
    
      module HashKeys
        # We want to use attributes as keys
        # for a hash-object, so we have to
        # overwrite the eql?- and hash-method
        # to make it work 
        def eql?(other)
          self.==(other)
        end
        def_sig :eql?, Attribute
    
        def hash
          # not the best algorithm for calculating a
          # hash but it works quite well
          self.class.object_id + id.object_id
        end
      end
      include HashKeys
    
      def clone
        # an attributes contains only an id
        self.class.new(id)
      end
    
      def inspect
        "<#{self.class.to_s.split('::').last} #{id}>"
      end
    end
    
    class Iter < Attribute; end
    def Iter(id)
      Iter.new(id)
    end
    class Pos < Attribute; end
    def Pos(id)
      Pos.new(id)
    end
    class Item < Attribute
    
    include Comparable
    def <=>(other)
      self.id <=> other.id
    end
    def_sig :<=>, Item
    
    end
    def Item(id)
      Item.new(id)
    end
    class NamedAttribute < Attribute
      attr_reader :name
     
      def initialize(name, id=0)
        @name = name
        super(id)
      end
    
      # we only accept positive integers as ids
      def id=(id)
        raise IdError, "#{id} less than 0" if id < 0
        @id = id 
      end
      def_sig :id=, Fixnum
     
      def to_xml
        # Be careful of classes that are nested in modules
        "#{name}#{nth id}".to_sym
      end
    
      # Equality for attributes is defined over
      # their class and id
      def ==(other)
        self.class == other.class and
        self.name == other.name and
        self.id == other.id
      end
    
      module HashKeys
        # We want to use attributes as keys
        # for a hash-object, so we have to
        # overwrite the eql?- and hash-method
        # to make it work 
        def eql?(other)
          self.==(other)
        end
        def_sig :eql?, Attribute
      
        def hash
          # not the best algorithm for calculating a
          # hash but it works quite well
          self.class.object_id + id.object_id + name.object_id
        end
      end
      include HashKeys
    
      def inspect
        "<#{self.class.to_s.split('::').last} name:#{name} id:#{id}>"
      end
    
      def clone
        # an attributes contains only an id
        NamedAttribute.new(name,id)
      end
    end
    def NamedAttribute(name, id=0)
      NamedAttribute.new(name,id)
    end
  
  end

end
