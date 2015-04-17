# encoding: UTF-8

require 'aws-sdk'

module S3console
  class Collection
    include Enumerable

    # Initialize
    #
    # @param [S3console::Console] console s3 console
    # @param [String] bucket S3 bucket name
    # @param [String] prefix S3 key prefix
    # @param [Logger] logger logging object
    # @return [S3console::Collection] S3 file collection
    def initialize(console, bucket = nil, prefix = nil, logger: nil)
      @console = console
      @bucket = bucket
      @prefix = prefix
      @logger = logger

      # object cache
      @objects = []
    end

    # Enumerate
    def each(&block)
      @bucket ? each_object(&block) : each_bucket(&block)
    end

    # Is empty?
    #
    # @return [Boolean] is empty collection?
    def empty?
      first.nil?
    end

    private

    def each_bucket(&block)
      @console.buckets.keys.each &block
    end

    def each_object(&block)
      # enumerate objects cache
      @objects.each(&block)

      # return when no more objects remain
      return self.each_entry if @is_truncated == false

      # try to enumerate more objects
      objects = list_objects
      loop do
        # break when no objects found
        objects || break

        # collect prefixes and keys
        @prefixes = objects.common_prefixes.collect(&:prefix).map { |d| d.sub(/^#{Regexp.quote(objects.prefix)}/, '') }
        @keys = objects.contents.collect(&:key).map { |f| f.sub(/^#{Regexp.quote(objects.prefix)}/, '') }

        # cache objects
        @objects += @prefixes + @keys

        # enumerate
        (@prefixes + @keys).each &block

        # break when no more objects remain
        @is_truncated || break

        objects = list_objects
      end

      # TODO: what should be returned exactly?
      self.each_entry
    end

    def client
      @client ||= begin
        bucket_region = @console.buckets[@bucket]
        bucket_region.nil? || bucket_region.empty? ? @console.client : Aws::S3::Client.new(region: bucket_region)
      end
    end

    def list_objects
      begin
        objects = client.list_objects(bucket: @bucket,
                                      delimiter: '/',
                                      prefix: @prefix,
                                      marker: @next_marker)
        @is_truncated = objects.is_truncated
        @next_marker = objects.next_marker
        objects
      rescue Aws::S3::Errors::NoSuchBucket => error
        @logger.error error
        # no such bucket, do not try <list_objects> again
        @is_truncated = false
        nil
      end
    end
  end # class Collection
end # module S3console