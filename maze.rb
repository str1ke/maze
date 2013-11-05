require 'gosu'
require 'awesome_print'

class Maze
  attr_accessor :grid, :grid_size_x, :grid_size_y, :x, :y, :win

  GRAY = Gosu::Color::GRAY
  BOX_SIZE     = 20
  BORDER_WIDTH = 3

  N = 1 << 0
  E = 1 << 1
  S = 1 << 2
  W = 1 << 3
  VISITED = 1 << 4

  OPPOSITE = { N => S, S => N, E => W, W => E }

  # N, S, E, W = 1, 2, 4, 8
  # DX         = { E => 1, W => -1, N =>  0, S => 0 }
  # DY         = { E => 0, W =>  0, N => -1, S => 1 }
  # OPPOSITE   = { E => W, W =>  E, N =>  S, S => N }

  def initialize(win = nil, n = 3, m = 3)
    @grid_size_x = n
    @grid_size_y = m
    @grid = Array.new(@grid_size_y) { Array.new(@grid_size_x) { 0 } }

    @x = 10
    @y = 10
    @win = win

    generate_maze
  end

  def generate_maze
    gen_path_from(0, 0)

    while point = find_starting_point
      gen_path_from(point[0], point[1])
    end
  end

  def first_step
    # @grid[0][0] |= S | E | VISITED
    # @grid[0][1] |= S | W | VISITED
    #@grid[0][2] |= N | VISITED
    # @grid[1][0] |= N | VISITED
    # @grid[1][1] |= N | E | VISITED
    # @grid[1][2] |= S | W | VISITED
    # @grid[2][0] |= E | VISITED
    # @grid[2][1] |= E | W | VISITED
    # @grid[2][2] |= N | W | VISITED

    point = find_starting_point
    ap point
    #gen_path_from(point[0], point[1])
  end

  def next_step
    point = find_starting_point
    gen_path_from(point[0], point[1])
  end

  def find_starting_point
    point = nil

    @grid.each_with_index do |line, y|
      line.each_with_index do |box, x|
        next if have_state(box, VISITED)

        neighbours_directions = directions(x, y).select do |d|
          have_state(box_by_direction(x, y, d), VISITED)
        end
        next if neighbours_directions.empty?

        neib = neighbours_directions.sample
        case neib
          when 'N'
            grid[y - 1][x] |= (self.class.const_get('OPPOSITE')[self.class.const_get(neib)] | VISITED)
          when 'E'
            grid[y][x + 1] |= (self.class.const_get('OPPOSITE')[self.class.const_get(neib)] | VISITED)
          when 'S'
            grid[y + 1][x] |= (self.class.const_get('OPPOSITE')[self.class.const_get(neib)] | VISITED)
          when 'W'
            grid[y][x - 1] |= (self.class.const_get('OPPOSITE')[self.class.const_get(neib)] | VISITED)
        end

        grid[y][x] |= self.class.const_get(neib)
        grid[y][x] |= VISITED

        can_go = where_can_go(x, y)
        next if can_go.empty?

        point = [x, y]
        return point
      end
    end

    point
  end

  def gen_path_from(x, y, debug = nil)
    can_go_to = where_can_go x, y

    until can_go_to.empty?
      direction = can_go_to.sample
      go x, y, direction

      break if debug

      y -= 1 if direction == 'N'
      y += 1 if direction == 'S'
      x += 1 if direction == 'E'
      x -= 1 if direction == 'W'

      can_go_to = where_can_go x, y
    end
  end

  def have_passes box
    [N, E, S, W].select { |dir| have_state(box, dir) }
  end

  def directions(x, y)
    neib = []

    neib << 'N' if y - 1 >= 0
    neib << 'E' if x + 1 < @grid_size_x
    neib << 'S' if y + 1 < @grid_size_y
    neib << 'W' if x - 1 >= 0

    neib
  end

  def where_can_go(x, y)
    directions(x,y).reject { |d| have_state(box_by_direction(x, y, d), VISITED) }
  end

  def go(x, y, direction)
    @grid[y][x] |= self.class.const_get(direction)
    @grid[y][x] |= VISITED

    case direction
      when 'N'
        @grid[y - 1][x] |= self.class.const_get('OPPOSITE')[self.class.const_get(direction)]
      when 'E'
        @grid[y][x + 1] |= self.class.const_get('OPPOSITE')[self.class.const_get(direction)]
      when 'S'
        @grid[y + 1][x] |= self.class.const_get('OPPOSITE')[self.class.const_get(direction)]
      when 'W'
        @grid[y][x - 1] |= self.class.const_get('OPPOSITE')[self.class.const_get(direction)]
    end
  end

  def box_by_direction(x, y, direction)
    case direction
      when 'N'
        @grid[y - 1][x]
      when 'E'
        @grid[y][x + 1]
      when 'S'
        @grid[y + 1][x]
      when 'W'
        @grid[y][x - 1]
    end
  end

  def have_state(box, state)
    box & state != 0
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
    walls = have_passes(box ^ 0b1111)

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