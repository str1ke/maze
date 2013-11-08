require 'gosu'
#require 'method_profiler'
require_relative 'maze'


class Game < Gosu::Window
  WIN_HEIGHT = 1000
  WIN_WIDTH  = 1920
  CAPTION = 'Mega Maze 3000'

  def initialize
    super WIN_WIDTH, WIN_HEIGHT, false
    self.caption = CAPTION

    #@profiler = MethodProfiler.observe(Maze)
    @maze = Maze.new self, 40
  end
  
  def button_down(id)
    case id
    when Gosu::KbR
      @maze.generate_new
    when Gosu::KbE
      @maze.clean
    when Gosu::KbN
      @maze.next_step
    when Gosu::KbC
      @maze.color = !@maze.color
    when Gosu::KbS
      @maze.solve
    when Gosu::KbQ
      close
    when Gosu::KbMinus
      @maze.decrease_box_size
      @maze.generate_new
    when Gosu::KbEqual
      @maze.increase_box_size
      @maze.generate_new
    end
  end

  def draw
    @maze.render
    #puts @profiler.report.sort_by(:total_time)
    #close
  end
end

Game.new.show