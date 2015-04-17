# encoding: UTF-8

require_relative 's3console/version'
require_relative 's3console/console'

module S3console
end

# Temporary code goes here...

s3console = S3console::Console.new

# TODO: switch to use S3console::Utils::Output.ls(files) to display files
while line = S3console::Utils::Input.gets("#{s3console.current_path}> ")
  case line.strip
    when ''
      # no thing to do
    when /^ls$/
      collection = s3console.ls
      count = 0
      collection.each_slice(100) do |a|
        puts a.join("\n")
        puts "  #{count += a.size} files ..."
        a.size == 100 && STDIN.getch == 'q' && break
      end
    when /^cd(\s+(.+))?$/
      if $2
        s3console.cd $2
        collection = s3console.ls

        if collection.empty?
          STDERR.puts "no such file or directory: #{$2}"
          s3console.cd '..'
        end
      else
        s3console.cd
      end
    when /exit/
      break
    else
      STDERR.puts "command not found: #{line}"
  end

  STDOUT.puts
end
