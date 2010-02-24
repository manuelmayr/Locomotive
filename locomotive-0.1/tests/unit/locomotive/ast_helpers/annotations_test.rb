require 'test/unit'
require 'importer'

import 'locomotive/ast_helpers/annotations'

module Locomotive

module AstHelpers

module Tests

module Unit

class TestAnnotations
  include Annotations
end

class AnnotationsTest < Test::Unit::TestCase

  def setup
    @test_ann = TestAnnotations.new
    @test_ann.ann_key1 = 42
  end

  def test_annotations
    assert_respond_to @test_ann, :ann_key=
    assert_respond_to @test_ann, :ann_key
    assert_equal      42, @test_ann.ann_key1
  end

  def test_assertions
    assert_raise(NoMethodError) { @test_ann.anno      }
    assert_raise(NoMethodError) { @test_ann.anno = 12 }
  end

end

end

end

end

end
