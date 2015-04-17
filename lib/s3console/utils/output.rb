# encoding: UTF-8

module S3console
  module Utils
    module Output
      SCREEN_WIDTH = 80
      SLICE_SIZE = 10

      # Puts files with format
      #
      # @param [Array<String>] files file names
      def puts_files(files)
        return if files.nil? || files.empty?
        max_size = files.map(&:size).max
        slice_size = SCREEN_WIDTH/max_size > 0 ? SCREEN_WIDTH/max_size : 1
        STDOUT.puts files
                      .sort
                      .map { |f| sprintf("%-#{max_size}s", f) }
                      .each_slice(slice_size)
                      .map { |a| a.join("\t") }
                      .join("\n")
      end

      # List up files of collection
      #
      # @param [S3console::Collection] collection s3 file collection
      def ls(collection)
        collection.each_slice(SLICE_SIZE) do |files|
          puts_files files

          STDOUT.puts ' *** Press <SPACE> to load more, press <Q> to quit *** '

          while c = STDIN.getch
            case c
              when ' '
                break
              when 'q'
                return
            end
          end
        end
      end

      module_function :ls

    end # module Output
  end # module Utils
end # module S3console