# encoding: UTF-8

require 'io/console'

module Utils
  module Input
    BACKSPACE = "\u007F"
    CTRL_C = "\u0003"
    CTRL_D = "\u0004"
    CTRL_L = "\f"
    ENTER = "\r"

    VALID_INPUT = %r/[a-zA-Z0-9 `~!@#\$%\^&\*\(\)_\-\+={\[}\]|\\:;"'<,>\.\?\/]/

    # TODO: handle <ESCAPE>
    # ESCAPE = "\e"
    UP= "\e[A"
    DOWN = "\e[B"
    LEFT = "\e[D"
    RIGHT = "\e[C"

    INVALID_INPUTS = [UP, DOWN, LEFT, RIGHT]

    def gets(prompt = '> ')
      s = '' # current input
      undefined_s = nil # undefined input

      STDOUT.print prompt
      while c = undefined_s || STDIN.getch
        # clear undefined input
        undefined_s = nil if undefined_s

        case c
          when CTRL_D
            # quit console
            exit
          when ENTER
            # confirm input (input finishes)
            STDOUT.puts
            break
          when CTRL_C
            # end current input, and start a new one
            s = ''
            STDOUT.puts
          when CTRL_L
            # clear screen, but keep current input
            clear
          when BACKSPACE
            # clear current output
            STDOUT.print "\r" + "#{prompt}#{s}".gsub(/./, ' ')
            # remove one character from current input
            s.sub!(/.$/, '')
            # flush current input
            STDOUT.print "\r#{prompt}#{s}"
          when VALID_INPUT
            # append new input
            s += c
          else
            # handle undefined input
            # skip all defined invalid inputs
            tmp = c
            loop do
              # don't break for partial match
              unless INVALID_INPUTS.any? { |ii| ii.split('').first(tmp.size).join == tmp }
                # TODO: write the last undefined character back
                # STDIN.write tmp.split('').last
                undefined_s = tmp.split('').last
                break
              end
              # break for full match
              break if INVALID_INPUTS.include?(tmp)
              # try to read one more defined/undefined character
              tmp += STDIN.getch
            end
            # dump undefined invalid inputs
            STDERR.puts("\n" + tmp.inspect + "\n") unless INVALID_INPUTS.include?(tmp)
        end

        # TODO: handle the case when input becomes multiple lines
        # flush current line
        STDOUT.print "\r#{prompt}#{s}"
      end

      # return input
      s
    end

    def clear
      STDOUT.print "\e[H\e[J"
    end

    module_function :gets, :clear

  end # module Input
end # module Utils