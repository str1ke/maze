require 'gosu'

class Maze
  attr_accessor :grid, :color, :box_size, :border_width

  WALL_COLOR   = Gosu::Color::GRAY
  GREEN_COLOR  = Gosu::Color.argb(0xff3BFF48)
  YELLOW_COLOR = Gosu::Color.argb(0xffFFED75)
  RED_COLOR    = Gosu::Color.argb(0xffFF7585)
  BLUE_COLOR   = Gosu::Color.argb(0xff85C6FF)
  BLACK_COLOR  = Gosu::Color::BLACK

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

  def initialize(win = nil, b_size)
    @x = 0
    @y = 0
    @win = win
    @color = true

    set_box_size(b_size)
    generate_new
  end

  def box_size=(val)
    if val < 10
      scale_factor = 5
    else
      scale_factor = 10
    end
    b_width = val / scale_factor
    b_width = 1 if b_width < 1

    @box_size = val
    @border_width = b_width
  end

  def set_box_size(b_size)
    self.box_size = b_size

    row_count = @win.height / (b_size - border_width)
    col_count = @win.width / (b_size - border_width)

    @grid_size_x = col_count
    @grid_size_y = row_count
  end

  def decrease_box_size
    self.box_size -= step
  end

  def increase_box_size
    self.box_size += step
  end

  def step
    (box_size >= 5 && box_size < 10) ? 2 : 5
  end

  def generate_new
    clean
    generate_maze
  end

  def next_step
    if @first_step
      gen_path_from(0, 0, YELLOW)
      @first_step = false
      true
    else
      if point = find_starting_point
        gen_path_from(point[0], point[1], YELLOW)
        true
      else
        false
      end
    end
  end

  def generate_maze
    nil while next_step
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
          go(x, y, visited_neighbours.sample, YELLOW) if !have_state(box, VISITED)
          next
        end

        go(x, y, visited_neighbours.sample, YELLOW)
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
    pos_x = @x + x * box_size - x * border_width
    pos_y = @y + y * box_size - y * border_width

    # calc walls
    walls = have_passes(box ^ 0b1111)

    background(pos_x, pos_y, box_color(box))
    draw_vline(pos_x, pos_y) if walls.include? W
    draw_hline(pos_x, pos_y) if walls.include? N
    draw_vline(pos_x + box_size - border_width, pos_y) if walls.include? E
    draw_hline(pos_x, pos_y + box_size - border_width) if walls.include? S
  end

  def box_color(box)
    return BLACK_COLOR unless color

    return GREEN_COLOR  if have_state(box, GREEN)
    return YELLOW_COLOR if have_state(box, YELLOW)
    return RED_COLOR    if have_state(box, RED)
    return BLUE_COLOR   if have_state(box, BLUE)

    return BLACK_COLOR
  end

  def clean
    @grid = Array.new(@grid_size_y) { Array.new(@grid_size_x) { 0 } }
    @first_step = true
  end

  def draw_vline(x, y)
    @win.draw_quad(
      x, y, WALL_COLOR,
      x + border_width, y, WALL_COLOR,
      x, y + box_size, WALL_COLOR,
      x + border_width, y + box_size, WALL_COLOR, 2
    )
  end

  def draw_hline(x, y)
    @win.draw_quad(
      x, y, WALL_COLOR,
      x + box_size, y, WALL_COLOR,
      x, y + border_width, WALL_COLOR,
      x + box_size, y + border_width, WALL_COLOR, 2
    )
  end

  def background(x, y, c)
    @win.draw_quad(
      x, y, c,
      x + box_size, y, c,
      x, y + box_size, c,
      x + box_size, y + box_size, c, 1
    )
  end

  def render
    @grid.each_with_index do |line, y|
      line.each_with_index do |box, x|
        draw_box x, y, box
      end
    end
  end
end