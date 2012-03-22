module Locomotive

module Utilities

class RelAlg2XML

  private

  class << self
    def define_content_ranks(*mtds)
      mtds.each do |mtd|
        name = "content_#{mtd}".to_sym
        define_method(name) do |ast|
          cols = []
          cols << column(nil, :name => ast.ann_res, :new => true)
          pos = -1
          ast.ann_order.keys.each do |ord|
            cols << column(nil, :name => ord, :function => "sort",
                                   :pos => pos += 1,
                                   :direction => ast.ann_order[ord],
                                   :new => false)
          end
      
          pos = -1
          ast.ann_part.each do |part|
            cols << column(nil, :name => part, :function => "part",
                                   :pos => pos + 1,
                                   :new => false)
          end
      
          cols.join("\n")
        end
      end
    end

    def define_content_cmp(*mtds)
      mtds.each do |mtd|
        name = "content_#{mtd}".to_sym
        define_method(name) do |ast|
          cols = []
          cols << "<kind name=\"#{ast.ann_fun_kind}\"/>"
          cols << column(nil, :name => ast.ann_result, :new => true)
          cols << column(nil, :name => ast.ann_operands.first, :new => false, :position => 1)
          cols << column(nil, :name => ast.ann_operands.last, :new => false, :position => 2)
          cols.join("\n")
        end
      end
    end

  end

  def edge(attrs)
    attrlist = []
    attrs.keys.each do |attr|
      attrlist << "#{attr}=\"#{attrs[attr]}\""
    end

    "<edge #{attrlist.join(" ")}/>"
  end

  def schema(schema)
    cols = []
    schema.keys.each do |col|
      cols << "<col name=\"#{col.to_s}\"" \
                 " types=\"#{schema[col].join(",")}\"/>"
    end
    cols.join("\n")
  end

  def value(inner_node, attrs)
    attrlist = []
    attrs.keys.each do |attr|
      attrlist << "#{attr}=\"#{attrs[attr]}\""
    end

    "<value #{attrlist.join(" ")}#{inner_node ? ">" : "/>"}" \
    "#{inner_node}#{inner_node ? "</value>" : ""}"
  end

  def column(inner_node, attrs)
    attrlist = []
    attrs.keys.each do |attr|
      attrlist << "#{attr}=\"#{attrs[attr]}\""
    end

    "<column #{attrlist.join(" ")}#{inner_node ? ">\n" : "/>"}" \
    "#{inner_node}#{inner_node ? "\n</column>" : ""}"
  end

  public

  define_content_ranks :rowid, :rank, :rownum
  define_content_cmp   :eq, :lt, :gt, :leq, :geq

  def initialize(ast)
    @ast = ast
    # create an identifier for each node by a preorder-traversal
    # and enhance it by an xmlid-annotation
    id = 0
    @ast.traverse do |ast|
      ast.ann_xmlid = (id += 1)
    end
  end

  def content_table(ast)
    cols = []
    ast.ann_values.keys.each do |col|
      cols << column(value(ast.ann_values[col], :type => ast.ann_schema[col].first),
                     :name => col, :new => true)
    end
    cols.join("\n")
  end

  def content_eqjoin(ast)
    cols = []
    cols << column(nil, :name => ast.ann_col1,  :new => false, :position => 1)
    cols << column(nil, :name => ast.ann_col2,  :new => false, :position => 2)
    cols.join("\n")
  end

  def content_project(ast)
    cols = [] 
    ast.ann_items.keys.each do |old|
      ast.ann_items[old].each do |new|
        cols << column(nil, :name => new, :old_name => old, :new => (new != old))
      end
    end
    cols.join("\n")
  end

  def content_cross(ast)
  end

  def content_union(ast)
  end

  def content_serialize_relation(ast)
    cols = []
    cols << column(nil, :name => ast.ann_iter, :new => false, :function => :iter)
    cols << column(nil, :name => ast.ann_pos, :new => false, :function => :pos)
    pos = 0
    ast.ann_items.each do |item|
      cols << column(nil, :name => item, :new => false, :function => :item, :position => pos)
      pos += 1
    end
    cols.join("\n")
  end

  def content_ref_tbl(ast)
    cols = []
    cols << "<table name=\"#{ast.value}\">"
    ast.ann_items.keys.each do |col|
      cols << column(nil, :name => col, :tname => ast.ann_items[col],
                          :type => ast.ann_schema[col].join(","))
    end
    cols << "</table>"
    cols.join("\n")
  end

  def content_attach(ast)
    cols = []
    col = ast.value.first.first
    cols << column(value(ast.value[col].first, :type => ast.ann_schema[col].first),
                   :name => col, :new => true)
    cols.join("\n")
  end

  def content_nil(ast)
  end

  def content_fun(ast)
    cols = []
    cols << "<kind name=\"#{ast.ann_fun_kind}\"/>"
    cols << column(nil, :name => ast.ann_result, :new => true)
    cols << column(nil, :name => ast.ann_operands.first, :new => false, :position => 1)
    cols << column(nil, :name => ast.ann_operands.last, :new => false, :position => 2)
    cols.join("\n")
  end

  def to_xml_wrapper(ast)
#<schema>
#{schema ast.ann_schema}
#</schema>
<<XMLNODE
<node id=\"#{ast.ann_xmlid.to_s}\" kind=\"#{ast.kind.to_s}\">
<content>
#{ content_method = "content_#{->(kind) {
                               if kind == "serialize relation".to_sym then
                                 :serialize_relation
                               else
                                 kind
                               end }[ast.kind]}"
  if !self.respond_to?(content_method) then
    "<nocontent/>"
  else
    self.send(content_method, ast)
  end}
</content>
#{edges = []
  edges << edge(:to => ast.left_child.ann_xmlid) if ast.has_left_child?
  edges << edge(:to => ast.right_child.ann_xmlid) if ast.has_right_child?
  edges.join("\n")
 }
</node>
XMLNODE
  end

  def to_xml
  
    node_list = []

    node_list << <<PROLOG
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<query_plan_bundle>
<query_plan id=\"0\">
<properties>
<property name=\"overallResultType\" value=\"TUPLE\"/>
</properties>
<logical_query_plan unique_names=\"true\">
PROLOG

    @ast.traverse_strategy = Locomotive::AstHelpers::PostOrderTraverse
    @ast.traverse do |ast|
      node_list << to_xml_wrapper(ast)
    end

node_list << <<EPILOG
</logical_query_plan>
</query_plan>
</query_plan_bundle>
EPILOG

    node_list.join("\n")
  end
end

end

end
