require "minitest/autorun"
require "worldgen/math"

include WorldGen

class TestWorldgen < MiniTest::Unit::TestCase
	def test_cube_root
		assert_equal 0.0,cube_root(0)
		assert_equal 2.0,cube_root(8)
	end

	def test_to_base
		assert_equal [0,0,0],to_base(0,2,3)
		assert_equal [0,0,1],to_base(1,2,3)
		assert_equal [0,1,0],to_base(2,2,3)
		assert_equal [0,1,1],to_base(3,2,3)
		assert_equal [1,0,0],to_base(4,2,3)
		assert_equal [1,0,1],to_base(5,2,3)
		assert_equal [1,1,0],to_base(6,2,3)
		assert_equal [1,1,1],to_base(7,2,3)
	end
end