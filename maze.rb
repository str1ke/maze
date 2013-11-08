require 'gosu'

class Maze
  attr_accessor :grid, :color, :box_size, :border_width, :solved

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
  SCANNED  = 1 << 5

  GREEN    = 1 << 6
  YELLOW   = 1 << 7
  RED      = 1 << 8
  BLUE     = 1 << 9

  DX       = { E => 1, W => -1, N =>  0, S => 0 }
  DY       = { E => 0, W =>  0, N => -1, S => 1 }
  OPPOSITE = { N => S, S =>  N, E =>  W, W => E }

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
    col_count = @win.width  / (b_size - border_width)

    @grid_size_x = col_count
    @grid_size_y = row_count
  end

  def decrease_box_size
    set_box_size(box_size - step) if (box_size - step) >= 3
  end

  def increase_box_size
    set_box_size(box_size + step)
  end

  def step
    box_size < 10 ? 2 : 5
  end

  def generate_new
    clean

    start = Time.new
    generate_maze
    generated_by = Time.new - start

    puts "stat: #{@grid_size_x*@grid_size_x} cells, #{generated_by.round(2)} secs"
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

    for y in @last_y..(@grid_size_y - 1)
      for x in @last_x..(@grid_size_x - 1)
        next if box_is(@grid[y][x], VISITED)

        visited_neighbours = directions(x, y).select do |d|
          box_is(box_by_direction(x, y, d), VISITED)
        end
        next if visited_neighbours.empty?

        can_go = where_can_go(x, y, VISITED)
        if can_go.empty?
          go(x, y, visited_neighbours.sample, YELLOW) if !box_is(@grid[y][x], VISITED)
          next
        end

        go(x, y, visited_neighbours.sample, YELLOW)

        @last_y = y
        @last_x = x
        return [x, y]
      end
      @last_x = 0
    end

    point
  end

  def gen_path_from(x, y, color = 0)
    can_go_to = where_can_go x, y, VISITED

    until can_go_to.empty?
      direction = can_go_to.sample
      go x, y, direction, color

      x += DX[direction]
      y += DY[direction]

      can_go_to = where_can_go x, y, VISITED
    end
  end

  def have_passes box
    [N, E, S, W].select { |dir| box_is(box, dir) }
  end

  def directions(x, y)
    neib = []

    neib << N if y - 1 >= 0
    neib << E if x + 1 < @grid_size_x
    neib << S if y + 1 < @grid_size_y
    neib << W if x - 1 >= 0

    neib
  end

  def where_can_go(x, y, state = nil, count_walls = false)
    sides = directions(x, y)
    sides.reject! { |d| box_is(box_by_direction(x, y, d), state) } if state
    sides.select! { |d| box_is(@grid[y][x], d) } if count_walls
    sides
  end

  def go(x, y, direction, color)
    @grid[y][x] |= ( direction | VISITED | color )
    @grid[y + DY[direction]][x + DX[direction]] |= (OPPOSITE[direction] | VISITED | color)
  end

  def box_by_direction(x, y, direction)
    @grid[y + DY[direction]][x + DX[direction]]
  end

  def box_is(box, state)
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

    return GREEN_COLOR  if box_is(box, GREEN)
    return YELLOW_COLOR if box_is(box, YELLOW)
    return RED_COLOR    if box_is(box, RED)
    return BLUE_COLOR   if box_is(box, BLUE)

    return BLACK_COLOR
  end

  def clean
    @grid = Array.new(@grid_size_y) { Array.new(@grid_size_x) { 0 } }
    @first_step = true
    @last_y = 0
    @last_x = 0
    @solved = false
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

  def solve(x = 0, y = 0, end_x = @grid_size_x-1, end_y = @grid_size_y-1)
    return if solved
    @solve_array = Array.new(@grid_size_y) { Array.new(@grid_size_x) }
    current_step = 0
    points, next_points, path = [], [], []

    @solve_array[y][x]  = current_step
    @grid[y][x]        |= (RED | SCANNED)
    points << [x, y]

    while !solved
      current_step += 1

      points.each do |(x, y)|
        we_will_go = where_can_go(x, y, SCANNED, true)

        we_will_go.each do |direction|
          step_x = x + DX[direction]
          step_y = y + DY[direction]
          @grid[step_y][step_x] &= 0b0000111111
          @grid[step_y][step_x] |= (RED | SCANNED)
          @solve_array[step_y][step_x] = current_step
          next_points << [step_x, step_y]

          self.solved = true if (step_x == end_x && step_y == end_y)
        end
      end

      points = next_points
      next_points = []
    end

    path << [end_x, end_y]

    while current_step != 0
      last_point = path[-1]
      current_step -= 1
      points = points_with_score(current_step)
      path << points.find do |(x, y)|
        where_can_go(x, y, nil, true).any? { |d| (x + DX[d] == last_point[0]) && (y + DY[d] == last_point[1]) }
      end
    end

    path.each do |(x, y)|
      @grid[y][x] &= 0b0000111111
      @grid[y][x] |= BLUE
    end
  end


  def points_with_score(current_step)
    points = []

    for y in 0...@grid_size_y
      for x in 0...@grid_size_x
        points << [x, y] if @solve_array[y][x] == current_step
      end
    end

    points
  end

end