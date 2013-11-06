require 'gosu'
require_relative 'maze'

class Game < Gosu::Window
  WIN_HEIGHT = 1000
  WIN_WIDTH  = 1920

  def initialize
    super WIN_WIDTH, WIN_HEIGHT, true
    self.caption = 'Terminal'

    @maze = Maze.new self, 110, 55
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
    when Gosu::KbQ
      close
    end
  end

  def draw
    @maze.render
  end
end

Game.new.show