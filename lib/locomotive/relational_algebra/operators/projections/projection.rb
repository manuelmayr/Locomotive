module Locomotive

  module RelationalAlgebra

    class ProjectList
      include Locomotive::XML
      def_node :column
    
      private
    
      attr_accessor :project_list
      def_sig :project_list=, { GenericAttribute => [ConstAttribute] }
      
      public
      delegate :[],
               :to_a,
               :to => :project_list
    
      def initialize(hash)
        self.project_list = hash
      end
    
      def old_items
        project_list.keys
      end
    
      def new_items
        project_list.values.flatten
      end
    
      def to_xml
        project_list.collect do |old,news|
          news.collect do |new|
            column :name => new.to_xml,
                   :old_name => old.to_xml,
                   :new => new != old
          end.join
        end.join
      end
    
      def clone
        ProjectList.new( project_list.clone )
      end
    end
    
    class Project < Unary
      private
    
      attr_reader :proj_list

      def to_project_list(list)
        case
          when Hash === list then
            ProjectList.new(list)
          when Array === list then
            ProjectList.new(list.collect do |item|
                              [item, [item]]
                            end.to_hash)
          when ProjectList === list then
            list
          else raise ArgumentError,
                     "list does not seem to be a projectlist"
        end
      end
    
      public
    
      def initialize(op, proj_list)
        @proj_list = to_project_list proj_list
        super(op)
      end
    
      def child=(op)
        unless op.schema.attributes?(proj_list.old_items)
          raise CorruptedSchema,
                "Schema #{op.schema.attributes} does not " \
                "contain all attributes of #{proj_list.old_items}."
        end
        proj_list.old_items.each do |old|
          proj_list[old].each do |new|
            schema[new] = op.schema[old]
          end
        end
        super(op)
      end
    
      def xml_content
        content do
          proj_list.to_xml
        end
      end
    
      def clone
        Project.new(child.clone, proj_list.clone)
      end
    
      def set(var,plan)
        Project.new(
          child.set(var,plan),
          proj_list.clone)
      end
    end

  end

end
