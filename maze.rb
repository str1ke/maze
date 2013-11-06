require 'gosu'
require 'awesome_print'

class Maze
  attr_accessor :grid, :color

  WALL_COLOR   = Gosu::Color::GRAY
  GREEN_COLOR  = Gosu::Color.argb(0xff3BFF48)
  YELLOW_COLOR = Gosu::Color.argb(0xffFFED75)
  RED_COLOR    = Gosu::Color.argb(0xffFF7585)
  BLUE_COLOR   = Gosu::Color.argb(0xff85C6FF)
  BLACK_COLOR  = Gosu::Color::BLACK

  BOX_SIZE     = 20
  BORDER_WIDTH = 3

  N        = 1 << 0
  E        = 1 << 1
  S        = 1 << 2
  W        = 1 << 3
  VISITED  = 1 << 4

  GREEN    = 1 << 5
  YELLOW   = 1 << 6
  RED      = 1 << 7
  BLUE     = 1 << 8

  DX       = { E => 1, W => -1, N =>  0, S => 0 }
  DY       = { E => 0, W =>  0, N => -1, S => 1 }
  OPPOSITE = { N => S, S => N, E => W, W => E }

  def initialize(win = nil, n = 3, m = 3)
    @grid_size_x = n
    @grid_size_y = m
    @x = 10
    @y = 10
    @win = win
    @color = true

    generate_new
  end

  def generate_new
    clean
    generate_maze
  end

  def next_step
    if @first_step
      gen_path_from(0, 0, GREEN) 
      @first_step = false      
    else
      if point = find_starting_point
        gen_path_from(point[0], point[1], YELLOW)
      end
    end
  end

  def generate_maze
    gen_path_from(0, 0, GREEN)

    while point = find_starting_point
      gen_path_from(point[0], point[1], YELLOW)
    end
  end

  def find_starting_point
    point = nil

    @grid.each_with_index do |line, y|
      line.each_with_index do |box, x|
        next if have_state(box, VISITED)

        visited_neighbours = directions(x, y).select do |d|
          have_state(box_by_direction(x, y, d), VISITED)
        end
        next if visited_neighbours.empty?

        can_go = where_can_go(x, y)
        if can_go.empty?
          go(x, y, visited_neighbours.sample, BLUE) if !have_state(box, VISITED)
          next
        end

        go(x, y, visited_neighbours.sample, RED)
        return [x, y]
      end
    end

    point
  end

  def gen_path_from(x, y, color = 0)
    can_go_to = where_can_go x, y

    until can_go_to.empty?
      direction = can_go_to.sample
      go x, y, direction, color

      x += DX[direction]
      y += DY[direction]

      can_go_to = where_can_go x, y
    end
  end

  def have_passes box
    [N, E, S, W].select { |dir| have_state(box, dir) }
  end

  def directions(x, y)
    neib = []

    neib << N if y - 1 >= 0
    neib << E if x + 1 < @grid_size_x
    neib << S if y + 1 < @grid_size_y
    neib << W if x - 1 >= 0

    neib
  end

  def where_can_go(x, y)
    directions(x, y).reject { |d| have_state(box_by_direction(x, y, d), VISITED) }
  end

  def go(x, y, direction, color)
    @grid[y][x] |= ( direction | VISITED | color )
    @grid[y + DY[direction]][x + DX[direction]] |= (OPPOSITE[direction] | VISITED | color)
  end

  def box_by_direction(x, y, direction)
    @grid[y + DY[direction]][x + DX[direction]]
  end

  def have_state(box, state)
    box & state != 0
  end

  def draw_box(x, y, box)
    pos_x = @x + x * BOX_SIZE - x * BORDER_WIDTH
    pos_y = @y + y * BOX_SIZE - y * BORDER_WIDTH

    # calc walls
    walls = have_passes(box ^ 0b1111)

    background(pos_x, pos_y, box_color(box))
    draw_vline(pos_x, pos_y) if walls.include? W
    draw_hline(pos_x, pos_y) if walls.include? N
    draw_vline(pos_x + BOX_SIZE - BORDER_WIDTH, pos_y) if walls.include? E
    draw_hline(pos_x, pos_y + BOX_SIZE - BORDER_WIDTH) if walls.include? S
  end

  def box_color(box)
    return BLACK_COLOR unless color

    return GREEN_COLOR  if have_state(box, GREEN)
    return YELLOW_COLOR if have_state(box, YELLOW)
    return RED_COLOR if have_state(box, RED)
    return BLUE_COLOR if have_state(box, BLUE)

    return BLACK_COLOR
  end

  def clean
    @grid = Array.new(@grid_size_y) { Array.new(@grid_size_x) { 0 } }
    @first_step = true
  end

  def draw_vline(x, y)
    @win.draw_quad(
      x, y, WALL_COLOR,
      x + BORDER_WIDTH, y, WALL_COLOR,
      x, y + BOX_SIZE, WALL_COLOR,
      x + BORDER_WIDTH, y + BOX_SIZE, WALL_COLOR, 2
    )
  end

  def draw_hline(x, y)
    @win.draw_quad(
      x, y, WALL_COLOR,
      x + BOX_SIZE, y, WALL_COLOR,
      x, y + BORDER_WIDTH, WALL_COLOR,
      x + BOX_SIZE, y + BORDER_WIDTH, WALL_COLOR, 2
    )
  end

  def background(x, y, c)
    @win.draw_quad(
      x, y, c,
      x + BOX_SIZE, y, c,
      x, y + BOX_SIZE, c,
      x + BOX_SIZE, y + BOX_SIZE, c, 1
    )
  end

  def render
    @grid.each_with_index do |line, y|
      line.each_with_index do |box, x|
        draw_box x, y, box
        if !have_state box, VISITED
          ap "#{x}, #{y}, #{box}"
        end
      end
    end
  end
end