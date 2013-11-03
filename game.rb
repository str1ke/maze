require 'gosu'
require_relative 'maze'

class Game < Gosu::Window
  WIN_HEIGHT = 1000
  WIN_WIDTH  = 1920

  def initialize
    super WIN_WIDTH, WIN_HEIGHT, false
    self.caption = 'Mega Maze 3000'

    @maze = Maze.new self, 20, 40
  end
  
  def update
    if button_down? Gosu::KbR then
      @maze = Maze.new self, 20, 40
    end
  
    if button_down? Gosu::KbQ
      close
    end
  end

  def draw
    @maze.render
  end
end

Game.new.show