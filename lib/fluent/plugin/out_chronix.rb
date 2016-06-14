module Fluent
  require 'base64'
  require 'msgpack'
  require 'protobuf'
  require 'rubygems'
  require 'rsolr'
  require 'zlib'
  require_relative 'proto/Point.rb'
  require_relative 'proto/StracePoint.rb'

  class ChronixOutput < BufferedOutput

    Fluent::Plugin.register_output('chronix', self)

    config_param :host, :string, :default => "localhost", :desc => "IP or hostname of chronix installation, default: localhost"
    config_param :port, :string, :default => "8983", :desc => "chronix port, default: 8983"
    config_param :path, :string, :default => "/solr/chronix/", :desc => "path to chronix, default: /solr/chronix/"
    config_param :threshold, :integer, :default => 10, :desc => "threshold for delta-calculation, every (delta - prev_delta) < threshold will be nulled"

    def configure(conf)
      super
      connectToChronix
    end

    def connectToChronix
      @url = "http://" + @host + ":" + @port + @path
      @solr = RSolr.connect :url => @url
    end # def connectToChronix

    def start
      super
    end

    def shutdown
      super
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      pointHash = createPointHash(chunk)

      documents = []
      # iterate through pointHash and zip all the data
      pointHash.each { |metric, phash|
        documents << createSolrDocument(metric, phash)
      }

      @solr.add documents
      @solr.update :data => '<commit/>'
    end

    # this method iterates through all events and creates a hash with different lists of points sorted by metric
    def createPointHash(chunk)
      pointHash = Hash.new

      # add each event to our hash, sorted by metrics as key
      chunk.msgpack_each {|(tag, time, record)|

        timestamp = time.to_i
        metric = record["metric"]

        # if there is no list for the current metric -> create a new one
        if pointHash[metric] == nil
          if record["chronix_type"] == "strace"
            pointHash[metric] = {"startTime" => timestamp, "lastTimestamp" => 0, "points" => Chronix::StracePoints.new, "prevDelta" => 0, "timeSinceLastDelta" => 0, "lastStoredDate" => timestamp}
          else
            pointHash[metric] = {"startTime" => timestamp, "lastTimestamp" => 0, "points" => Chronix::Points.new, "prevDelta" => 0, "timeSinceLastDelta" => 0, "lastStoredDate" => timestamp}
          end
        end

        if pointHash[metric]["lastTimestamp"] == 0
          delta = 0
        else
          delta = timestamp - pointHash[metric]["lastTimestamp"]
        end
    
        if (almostEquals(delta, pointHash[metric]["prevDelta"]) && noDrift(timestamp, pointHash[metric]["lastStoredDate"], pointHash[metric]["timeSinceLastDelta"]))
          # insert the current point in our list
          pointHash[metric]["points"].p << createChronixPoint(0, record["values"][0], record["chronix_type"])

          pointHash[metric]["timeSinceLastDelta"] += 1

        else
          # insert the current point in our list
          pointHash[metric]["points"].p << createChronixPoint(delta, record["values"][0], record["chronix_type"])

          pointHash[metric]["timeSinceLastDelta"] = 1
          pointHash[metric]["lastStoredDate"] = timestamp
        end

        # save current timestamp as lastTimestamp and the previousOffset
        pointHash[metric]["lastTimestamp"] = timestamp
        pointHash[metric]["prevDelta"] = delta

      } #end each

      return pointHash
    end

    def zipAndEncode(points)
      # encode protobuf-list
      proto_bytes = points.encode
      string_io = StringIO.new("w")
      
      # compress the encoded protobuf-list
      gz = Zlib::GzipWriter.new(string_io)
      gz.write(proto_bytes)
      gz.close
      data = string_io.string

      # encode base64 (without \n)
      return Base64.strict_encode64(data)
    end

    def createChronixPoint(delta, value, type = "")
      if type == "strace"
        return Chronix::StracePoint.new( :t => delta, :v => value )
      else
        return Chronix::Point.new( :t => delta, :v => value )
      end
    end

    def createSolrDocument(metric, phash)
      endTime = phash["lastTimestamp"] # maybe use startTime + delta here?!
      # add more meta-data in the future
      return { :metric => metric, :start => phash["startTime"], :end => endTime, :data => zipAndEncode(phash["points"]) }
    end

    # checks if two offsets are almost equals
    def almostEquals(delta, prevDelta)
      diff = (delta - prevDelta).abs

      return (diff <= @threshold)
    end

    # checks if there is a drift
    def noDrift(timestamp, lastStoredDate, timeSinceLastDelta)
      calcMaxOffset = @threshold * timeSinceLastDelta
      drift = lastStoredDate + calcMaxOffset - timestamp.to_i

      return (drift <= (@threshold / 2))
    end

  end
end

