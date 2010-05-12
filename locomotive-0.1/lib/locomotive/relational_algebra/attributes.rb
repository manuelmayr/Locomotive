module Locomotive

  module RelationalAlgebra


    class GenericAttribute; end
  
    class ConstAttribute
      protected
    
      def nth id
        if id == 0
          ""
        else
           id.to_s
        end
      end 

      # we only accept positive integers as ids
      def id=(id)
        raise IdError, "#{id} less than 0" if id < 0
        @id = id 
      end
      def_sig :id=, Fixnum
     
      public
     
      attr_reader :id
     
      def initialize(id=0)
        raise AbstractClassError,
              "#{self.class} is an abstract class" if self.class == ConstAttribute
        self.id = id
      end
    
   
      def inc(val=1)
        self.class.new(self.id + val)
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
        def_sig :eql?, ConstAttribute
    
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
    
    class Iter < ConstAttribute; end
    def Iter(id)
      Iter.new(id)
    end
    class Outer < Iter; end
    def Outer(id)
      Outer.new(id)
    end
    class Inner < Iter; end
    def Inner(id)
      Inner.new(id)
    end
    class Pos < ConstAttribute; end
    def Pos(id)
      Pos.new(id)
    end
    class Item < ConstAttribute
    
    include Comparable
    def <=>(other)
      self.id <=> other.id
    end
    def_sig :<=>, Item
    
    end
    def Item(id)
      Item.new(id)
    end

    class Attribute < GenericAttribute
      attr_reader :name
     
      def initialize(name)
        @name = name.to_s
      end
    
      # Equality for attributes is defined over
      # their class their name
      def ==(other)
        self.class == other.class and
        self.name == other.name
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
          self.class.object_id + name.object_id
        end
      end
      include HashKeys
    
      def inspect
        "<#{self.class.to_s.split('::').last} name:#{name}>"
      end
    
      def clone
        # an attributes contains only an id
        Attribute.new(name)
      end
    end
    def Attribute(name)
      Attribute.new(name)
    end
  
  end

end
