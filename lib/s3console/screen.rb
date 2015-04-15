# encoding: UTF-8

require 'curses'

class Screen

  def initialize
    @buffer = []
  end

  def init
    Curses.init_screen
  end

  def close
    Curses.close
  end

  def clear
    Curses.clear
  end

  def getch
    # TODO: flush screen
    Curses.getch
  end

  def gets
    # TODO: flush screen
    #  handle special inputs
    #   1. CTRL + L
    #   2. CTRL + C
    #   3. CTRL + D
    #   4. Arrows
  end

  def print(str = '')
    # TODO:
  end

  def puts(str = '')
    # TODO: break lines into buffer
    #  1. "\n"
    #  2. str.size > Curses.cols
    @buffer << str
  end

  def flush
    @buffer.last(Curses.lines).each_with_index do |l, i|
      Curses.setpos(i, 0)
      Curses.addstr(l)
    end
  end

  private :flush

end # class Screen
