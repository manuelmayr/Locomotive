require 'graphviz'

module Locomotive

module Utilities

class AST2Dot
  
  def initialize(ast)
    @ast = ast
    @graph = GraphViz.new( "G" )
    @graph.node[:color] = "#000000"
    @graph.node[:style] = "filled"
    @graph.node[:fillcolor] = "#2255ff"
    @graph.node[:shape] = "box"
    @graph.node[:margin] = "0.1"
    @graph
  end

  def toDot(ast)
    node = @graph.add_node(ast.hash.to_s, 
               :label => ast.kind.to_s + 
               ": " + ast.value.to_s + 
               "\n" +
               if ast.ann_xmlid then
                 "xml_id: " +
                 ast.ann_xmlid.to_s
               else
                 ""
               end + "\n" +
               if ast.ann_schema then
                 "schema: " + 
                 ast.ann_schema.to_s
               else
                 ""
               end
               )
    if ast.has_left_child? then
      @graph.add_edge(node, toDot(ast.left_child))
    end
    if ast.has_right_child? then
      @graph.add_edge(node, toDot(ast.right_child))
    end
    node
  end

  def out
    toDot(@ast)
    @graph.output( :pdf => "foo.pdf", :dot => "foo.dot" )
  end

end

end

end
