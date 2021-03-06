require 'byebug'
require 'awesome_print'
require './lib/node.rb'
require 'forwardable'

module QuadTree
class Tree
  # Config =====================================================================

  extend Forwardable

  DEFAULT_NODE = { x_max: 100, y_max: 100, x: 0, y: 0 }

  attr_reader :root

  def_delegators :@root, :to_s, :collect_points, :count_points

  # Delegates point adding method to @root and return the tree itself to chain calls
  %i(<< add_point add).each do |method_name|
    define_method(method_name) do |*point|
      @root.send method_name, point
      self
    end
  end

  # Class declaration ==========================================================

  def initialize(node_attributes = {})
    node_attributes = DEFAULT_NODE.merge node_attributes

    @root = QuadTree::Node.new node_attributes
  end

  # Return count random points
  # if a block is given, random point is available directly inside it
  def random_point(count = 1)
    points = get_random_points count

    points.each { |point| yield point } if block_given?

    points.count == 1 ? points.flatten(1) : points
  end

  # Return the depth of a given point
  def point_depth(*point)
    point.flatten! # Ensure we have 1-D array
    raise ArgumentError, "More than 2 coordinates received" if point.size > 2

    point_depth_rec(point, 1, root)
  end

  # Return an array of point in the neighborhood
  def find_neighbors(*point)
    point.flatten! # Ensure we have 1-D array
    raise ArgumentError, "More than 2 coordinates received" if point.size > 2

    find_neighbors_rec(point, root)
  end

  private

    def find_neighbors_rec(point, node)
      if node.points.include? point
        if node.is_leaf?
          return node.points - [point]
        else
          return node.childrens.values.inject([]) do |neighbors, child|
            neighbors += collect_childs_points(child)
          end
        end
      end

      return [] if node.is_leaf?

      node.childrens.values.inject([]) do |neighbors, child|
        neighbors += find_neighbors_rec(point, child)
      end
    end

    def collect_childs_points(node)
      return node.points if node.is_leaf?

      node.points + node.childrens.values.inject([]) do |points, child|
        points += collect_childs_points(child)
      end
    end

    def point_depth_rec(point, depth, node)
      return depth if node.points.include? point
      return 0 if node.is_leaf?

      node.childrens.values.inject(0) do |max, child|
        max += point_depth_rec(point, depth + 1, child)
      end
    end

    def get_random_points(count)
      x_range = (@root.x.to_i)..(@root.x_max.to_i)
      y_range = (@root.y.to_i)..(@root.y_max.to_i)
      points = []

      count.times do
        break if points.count == (@root.x_max + 1) * (@root.x_max + 1)

        point = []
        begin
          point = [Random.rand(x_range), Random.rand(y_range)]
        end while points.include? point

        points << point
      end

      points
    end

end
end
