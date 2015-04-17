# encoding: UTF-8

# require 's3console/version'
#
# module S3console
#   # Your code goes here...
# end

# Temporary code goes here...

require 'aws-sdk'
require 'logger'

require_relative 's3console/utils'

module S3console
  class Console
    S3_PATH_PREFIX = 's3://'

    attr_reader :client,
                :current_path,
                :is_truncated, :next_marker

    attr_accessor :max_keys

    def initialize(logger: nil)
      @client = Aws::S3::Client.new(region: 'us-east-1')
      @current_path = S3_PATH_PREFIX
      @logger = logger || Logger.new('/tmp/s3_console.log')
      @max_keys = 100
    end

    def ls
      return list_buckets.keys unless current_bucket
      objects = list_objects
      return [] unless objects
      directories = objects.common_prefixes.collect(&:prefix).map { |d| d.sub(/^#{Regexp.quote(objects.prefix)}/, '') }
      files = objects.contents.collect(&:key).map { |f| f.sub(/^#{Regexp.quote(objects.prefix)}/, '') }

      directories + files
    end

    def _cd(path)
      case path
        when '/'
          S3_PATH_PREFIX
        when '.'
          @current_path
        when '..'
          if root?
            S3_PATH_PREFIX
          else
            path = File.split(@current_path).first
            path == 's3:' ? S3_PATH_PREFIX : File.join(path, '/')
          end
        else
          File.join @current_path, path, '/'
      end
    end

    private :_cd

    def cd(path = nil)
      @is_truncated = false
      @next_marker = nil

      return (@current_path = S3_PATH_PREFIX) unless path

      File.split(path).each { |p| @current_path = _cd(p) }

      @current_path
    end

    def root?
      @current_path == S3_PATH_PREFIX
    end

    private

    def current_bucket
      @current_path.scan(%r|#{S3_PATH_PREFIX}([^/]+)|).flatten.first
    end

    def current_prefix
      @current_path.scan(%r|#{S3_PATH_PREFIX}[^/]+/(.+)|).flatten.first
    end

    def list_buckets
      @buckets ||= @client
                     .list_buckets
                     .buckets
                     .map { |b| [b.name, @client.get_bucket_location(bucket: b.name).location_constraint] }
                     .to_h
    end

    def list_objects
      @logger.info "bucket: #{current_bucket}, prefix: #{current_prefix}"
      return unless current_bucket
      bucket_region = list_buckets[current_bucket]
      c = bucket_region.nil? || bucket_region.empty? ? client : Aws::S3::Client.new(region: bucket_region)
      begin
        objects = c.list_objects(bucket: current_bucket,
                                 delimiter: '/',
                                 prefix: current_prefix,
                                 max_keys: @max_keys,
                                 marker: @next_marker)
        @is_truncated = objects.is_truncated
        @next_marker = objects.next_marker
        objects
      rescue Aws::S3::Errors::ServiceError => error
        @logger.error error.message
        nil
      end
    end
  end # class Console
end # module S3console

$s3console = S3console::Console.new

# print_files $s3console.ls
while line = S3console::Utils::Input.gets("#{$s3console.current_path}> ")
  case line.strip
    when /^ls$/
      # ls_files
      STDOUT.puts $s3console.ls.join("\n")
    when /^cd(\s+(.+))?$/
      if $2
        $s3console.cd $2
        files = $s3console.ls

        if files.nil? || files.empty?
          STDERR.puts "no such file or directory: #{$2}"
          $s3console.cd '..'
        end
      else
        $s3console.cd
      end
    when /exit/
      break
    else
      STDERR.puts "command not found: #{line}"
  end

  STDOUT.puts
end
