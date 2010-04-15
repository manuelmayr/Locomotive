module Locomotive

  module RelationalAlgebra
  
    class Predicate
      include Locomotive::XML
      def_node :column, :comparison
    
      private
    
      def first=(first)
        @first = first
      end
      def_sig :first=, Attribute
    
      def second=(snd)
        @second = snd
      end
      def_sig :second=, Attribute
    
      public
    
      attr_reader :first,
                  :second
    
      def initialize(first_, second_)
        self.first,
        self.second = first_, second_
      end
    
      def clone
        self.class.new(first.clone,second.clone)
      end
    end
    
    
    class Equivalence < Predicate
      def to_xml
        comparison :kind => :eq do
          [column(:name => first.to_xml, :new => false, :position => 1),
           column(:name => second.to_xml, :new => false, :position => 2)].join
        end
      end
    end
    
    
    class PredicateList
      include Locomotive::XML
      def_node :content
    
      private
    
      attr_accessor :pred_list
      def_sig :pred_list=, [Predicate]
    
      public
      delegate :[],
               :to_a,
               :to => :pred_list
    
      def initialize(*ary)
        self.pred_list = ary
      end
    
      def to_xml
        pred_list.collect do |pred|
          pred.to_xml
        end.join
      end
    
      def clone
        PredicateList.new( *pred_list.clone )
      end
    end

  end

end
