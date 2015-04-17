# encoding: UTF-8

require 'aws-sdk'
require 'logger'

require_relative 'utils'
require_relative 'collection'

module S3console
  class Console
    S3_PATH_PREFIX = 's3://'

    attr_reader :client,
                :buckets,
                :current_path

    # Initialize
    #
    # @param [Logger] logger logging object
    # @return [S3console::Console] s3 console
    def initialize(logger: nil)
      @logger = logger || Logger.new('/tmp/s3console.log')
      @client = Aws::S3::Client.new(region: 'us-east-1')
      @buckets = list_buckets
      @current_path = S3_PATH_PREFIX
    end

    # Is at root?
    #
    # @return [Boolean] is S3 root?
    def root?
      @current_path == S3_PATH_PREFIX
    end

    # The current bucket
    #
    # @return [String] S3 bucket name
    def current_bucket
      @current_path.scan(%r|#{S3_PATH_PREFIX}([^/]+)|).flatten.first
    end

    # The current prefix
    #
    # @return [String] S3 key prefix
    def current_prefix
      @current_path.scan(%r|#{S3_PATH_PREFIX}[^/]+/(.+)|).flatten.first
    end

    # List files
    #
    # @return [S3console::Collection] S3 file collection
    def ls
      Collection.new self, current_bucket, current_prefix, logger: @logger
    end

    # Change directory
    #
    # @return [String] the current path
    def cd(path = nil)
      @is_truncated = false
      @next_marker = nil

      return (@current_path = S3_PATH_PREFIX) unless path

      # split path
      paths = []
      tmp_path = path
      loop do
        tmp_path, last_path = File.split(tmp_path)
        paths.unshift last_path
        if tmp_path == '/' || tmp_path == '.'
          paths.unshift tmp_path
          break
        end
      end

      paths.each { |p| @current_path = cd_single_path(p) }

      @current_path
    end

    private

    # Change directory with single path
    #   Single path is path that doesn't include file separator
    #
    # @param [String] path single path
    # @return [String] path after changed
    def cd_single_path(path)
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

    # List S3 buckets
    #
    # @return [Hash<String, String>] key: S3 bucket name
    #                                value: S3 bucket region
    def list_buckets
      @buckets ||= @client
                     .list_buckets
                     .buckets
                     .map { |b| [b.name, @client.get_bucket_location(bucket: b.name).location_constraint] }
                     .to_h
    end
  end # class Console
end # module S3console