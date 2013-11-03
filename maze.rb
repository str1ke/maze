require 'gosu'
require 'awesome_print'

class Maze
  attr_accessor :grid, :grid_size_x, :grid_size_y, :x, :y, :win

  GRAY = Gosu::Color::GRAY
  BOX_SIZE     = 50
  BORDER_WIDTH = 3

  N = 1 << 0
  E = 1 << 1
  S = 1 << 2
  W = 1 << 3
  VISITED     = 1 << 4
  INITIALIZED = 1 << 5
  MASK        = 0b11111111
  OPPOSITE = { N => S, S => N, E => W, W => E }

  def initialize(win = nil, n = 3, m = 3)
    @grid_size_x = n
    @grid_size_y = m
    @grid = Array.new(@grid_size_x) { Array.new(@grid_size_y) { MASK } }

    @x = 10
    @y = 10
    @win = win

    generate_maze
  end

  def generate_maze    
    # @grid_size_x.times do |i|
    #   @grid_size_y.times { |j| grid[i][j] = random_box }
    # end
    
    # grid[0][0] = S
    # grid[0][1] = E
    # grid[0][2] = S | W
    # grid[1][0] = N | S
    # grid[1][1] = E | S
    # grid[1][2] = N | W | S
    # grid[2][0] = N | E
    # grid[2][1] = N | W
    # grid[2][2] = N

    x = 0
    y = 0
    prev_direction = nil

    9.times do
      box_neighbours = neighbours(x, y)
      # ap box_neighbours

      can_go_to = have_pass(box_neighbours)
      # ap can_go_to

      unless can_go_to.empty?
        direction = can_go_to.sample
        ap direction

        grid[y][x] = VISITED | self.class.const_get(direction)
        grid[y][x] |= Maze::OPPOSITE[self.class.const_get(prev_direction)] if prev_direction

        y -= 1 if direction == 'N'
        y += 1 if direction == 'S'
        x += 1 if direction == 'E'
        x -= 1 if direction == 'W'

        prev_direction = direction
      end
    end

    # grid[0][0] = 1
    # grid[0][1] = 2
    # grid[0][2] = 3
    # grid[1][0] = 4
    # grid[1][1] = 5
    # grid[1][2] = 6
    # grid[2][0] = 7
    # grid[2][1] = 8
    # grid[2][2] = 9
  end

  def box_directions box
    directions = []

    [N, E, S, W].each do |dir|
      directions << dir if (box & dir) != 0
    end

    directions
  end

  def neighbours(x, y)
    neib = []
    #top
    neib << [ 'N', grid[y - 1][x] ] if y - 1 >= 0

    #right
    neib << [ 'E', grid[y][x + 1] ] if x + 1 < @grid_size_x

    #bottom
    neib << [ 'S', grid[y + 1][x] ] if y + 1 < @grid_size_y

    #left
    neib << [ 'W', grid[y][x - 1] ] if x - 1 >= 0

    neib
  end

  def have_pass(neighbours)
    neighbours.map { |dir, box| dir if (box_directions(box).include? self.class::OPPOSITE[self.class.const_get(dir)]) }.compact
  end

  def is_visited(x, y)
    grid[y][x] & VISITED != 0
  end

  def random_box
    sides = [N, E, S, W]
    box   = 0
    (Random.rand(4) + 1).times { box |= sides.shuffle!.pop }
    box
  end


  def draw_box(x, y, box)
    pos_x = @x + x * BOX_SIZE - x * BORDER_WIDTH
    pos_y = @y + y * BOX_SIZE - y * BORDER_WIDTH

    # calc walls
    walls = box_directions(box ^ 0b1111)

    draw_vline(pos_x, pos_y) if walls.include? W
    draw_hline(pos_x, pos_y) if walls.include? N
    draw_vline(pos_x + BOX_SIZE - BORDER_WIDTH, pos_y) if walls.include? E
    draw_hline(pos_x, pos_y + BOX_SIZE - BORDER_WIDTH) if walls.include? S
  end

  def draw_vline(x, y)
    @win.draw_quad(
      x, y, GRAY,
      x + BORDER_WIDTH, y, GRAY,
      x, y + BOX_SIZE, GRAY,
      x + BORDER_WIDTH, y + BOX_SIZE, GRAY
    )
  end

  def draw_hline(x, y)
    @win.draw_quad(
      x, y, GRAY,
      x + BOX_SIZE, y, GRAY,
      x, y + BORDER_WIDTH, GRAY,
      x + BOX_SIZE, y + BORDER_WIDTH, GRAY
    )
  end

  def render
    @grid_size_x.times do |i|
      @grid_size_y.times { |j| draw_box j, i, grid[i][j] }
    end
  end
end