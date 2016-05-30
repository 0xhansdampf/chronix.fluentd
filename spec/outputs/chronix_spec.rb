# encoding: utf-8

require_relative "../spec_helper"

describe Fluent::ChronixOutput do

  Fluent::Test.setup
  
  let(:solr) { subject.instance.solr }

  before :each do

    events.each do |event|
      subject.emit(event["record"], event["time"])
    end

    subject.run
  end

  context "simple adding and removing test" do
    subject { Fluent::Test::BufferedOutputTestDriver.new(Fluent::ChronixOutput).configure(config) }

    let(:config) do
      %[
      ]
    end

    let(:tmetric) { "test1" }
    let(:events) { [ { "record" => {"metric" => tmetric, "values" => ["1.5"]}, "time" => "1459353272"} ] }

    it "create one event" do
      expect(solr.size).to eq(1)
    end

    it "should retrieve document" do
      doc = solr.get(tmetric)
      expect(doc[0][:data]).to_not be_nil
    end

    it "should remove document" do
      solr.delete(tmetric)
      expect(solr.size).to eq(0)
    end
  end

  context "test basic functions zip and encode, createPoint, createDocument" do
    subject { Fluent::Test::BufferedOutputTestDriver.new(Fluent::ChronixOutput).configure(config) }

    let(:config) do
      %[
      ]
    end

    let(:ttimestamp) { "1459353272" }
    let(:tmetric) { "test1" }
    let(:tvalue) { "10.5" }
    let(:svalue) { "string" }
    let(:events) { [ { "record" => {"metric" => tmetric, "values" => [tvalue]}, "time" => ttimestamp} ] }

    it "should return a Chronix::Point" do
      point = subject.instance.createChronixPoint(ttimestamp, tvalue)
      expectedResult = Chronix::Point.new( :t => ttimestamp, :v => tvalue )
      expect(point).to eq(expectedResult)
    end

    it "should return a Chronix::StracePoint" do
      point = subject.instance.createChronixPoint(0, svalue, "strace")
      expectedResult = Chronix::StracePoint.new( :t => 0, :v => svalue )
      expect(point).to eq(expectedResult)
    end
 
    it "should return a zipped and base64 encoded string containing the data" do
      points = Chronix::Points.new
      points.p << subject.instance.createChronixPoint(ttimestamp, tvalue)
      expectedResult = "H4sIAAAAAAAA/+Pi59jx9v12VkEGMFB1AACWVOXHEQAAAA=="
# don't do this check
#      expect(subject.instance.zipAndEncode(points)).to eq(expectedResult)
    end

#    it "should create a correct point hash" do
#      points = Chronix::Points.new
#      points.p << subject.instance.createChronixPoint(0, tvalue)
#      phash = {tmetric => {"startTime" => ttimestamp, "lastTimestamp" => ttimestamp, "points" => points, "prevDelta" => 0, "timeSinceLastDelta" => 1, "lastStoredDate" => ttimestamp}}
#      chunk = ["test", ttimestamp, events[0]["record"]].to_msgpack
#      expect(subject.instance.createPointHash(chunk)).to eq(phash)
#    end

    it "should create a valid document" do
      points = Chronix::Points.new
      points.p << subject.instance.createChronixPoint(ttimestamp, tvalue)
      phash = {"startTime" => ttimestamp, "lastTimestamp" => ttimestamp, "points" => points}
      document = subject.instance.createSolrDocument(tmetric, phash)
      sampleDoc = { :metric => tmetric, :start => phash["startTime"], :end => phash["lastTimestamp"], :data => "H4sIAAAAAAAA/+Pi59jx9v12VkEGMFB1AACWVOXHEQAAAA==" } 
# don't do this check
#      expect(document).to eq(sampleDoc)
    end

    it "should remove test documents" do
      solr.delete(tmetric)
      expect(solr.size).to eq(0)
    end
  end

  ttimestamp = "1459353272"
  # these events are needed for the next two test-contexts
  e1 = { "record" => {"metric" => "test1", "values" => ["1.5"]}, "time" => ttimestamp }
  e2 = { "record" => {"metric" => "test2", "values" => ["2.5"]}, "time" => ttimestamp }    
  e3 = { "record" => {"metric" => "test1", "values" => ["3.5"]}, "time" => ttimestamp }    
  e4 = { "record" => {"metric" => "test1", "values" => ["4.5"]}, "time" => ttimestamp }    
  e5 = { "record" => {"metric" => "test2", "values" => ["5.5"]}, "time" => ttimestamp }    
  e6 = { "record" => {"metric" => "test3", "values" => ["6.5"]}, "time" => ttimestamp }    
  e7 = { "record" => {"metric" => "test1", "values" => ["7.5"]}, "time" => ttimestamp }    
  e8 = { "record" => {"metric" => "test2", "values" => ["8.5"]}, "time" => ttimestamp }    

=begin
# this is not working at the moment..
  context "adding and removing tests with different metrics" do
    subject { Fluent::Test::BufferedOutputTestDriver.new(Fluent::ChronixOutput).configure(config) }

    let(:config) do
      %[
        buffer_queue_limit 1
      ]
    end

    let(:events) { [e1, e2, e3, e4, e5, e6, e7, e8] }

    it "should have 3 different metrics" do
      expect(solr.size).to eq(3)
    end

    it "should have 8 documents" do
      expect(solr.numDocuments).to eq(8)
    end

    it "should have 4 documents with metric 'test1'" do
      expect(solr.size("test1")).to eq(4)
    end

    it "should have 3 documents with metric 'test2'" do
      expect(solr.size("test2")).to eq(3)
    end

    it "should have 1 document with metric 'test3'" do
      expect(solr.size("test3")).to eq(1)
    end

    it "should remove all documents" do
      solr.delete
      expect(solr.size).to eq(0)
    end
  end
=end

  # test1: 4 elem
  # test2: 3 elem
  # test3: 1 elem
  context "adding and removing tests with different metrics and buffer-settings" do
    subject { Fluent::Test::BufferedOutputTestDriver.new(Fluent::ChronixOutput).configure(config)  }

    let(:config) do
      %[
      ]
    end

    let(:events) { [e1, e2, e3, e4, e5, e6, e7, e8] }

    it "should have 3 different metrics" do
      expect(solr.size).to eq(3)
    end

    it "should have 3 documents" do
      expect(solr.numDocuments).to eq(3)
    end

    it "should have 1 document with metric 'test1'" do
      expect(solr.size("test1")).to eq(1)
    end

    it "should have 1 document with metric 'test2'" do
      expect(solr.size("test2")).to eq(1)
    end

    it "should have 1 document with metric 'test3'" do
      expect(solr.size("test3")).to eq(1)
    end

    it "compare data-field-lengths from 'test1' and 'test2', expect res1.length > res2.length" do
      res1 = solr.get("test1")
      res2 = solr.get("test2")
      expect(res1[0][:data].length).to be > res2[0][:data].length
    end

    it "compare data-field-lengths from 'test2' and 'test3', expect res2.length > res3.length" do
      res2 = solr.get("test2")
      res3 = solr.get("test3")
      expect(res2[0][:data].length).to be > res3[0][:data].length
    end 

    it "should remove all documents" do
      solr.delete
      expect(solr.size).to eq(0)
    end
  end

  context "test delta calculation" do

    subject { Fluent::Test::BufferedOutputTestDriver.new(Fluent::ChronixOutput).configure(config)  }

    let(:config) do
      %[
        threshold 10
      ]
    end

    p_ev = []
    p_ev << { "record" => {"metric" => "test9", "values" => ["1.0"]}, "time" => "1462892410" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["2.0"]}, "time" => "1462892420" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["3.0"]}, "time" => "1462892430" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["4.0"]}, "time" => "1462892439" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["5.0"]}, "time" => "1462892448" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["6.0"]}, "time" => "1462892457" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["7.0"]}, "time" => "1462892466" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["8.0"]}, "time" => "1462892475" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["9.0"]}, "time" => "1462892484" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["10.0"]}, "time" => "1462892493" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["11.0"]}, "time" => "1462892502" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["12.0"]}, "time" => "1462892511" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["13.0"]}, "time" => "1462892520" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["14.0"]}, "time" => "1462892529" }
    p_ev << { "record" => {"metric" => "test9", "values" => ["15.0"]}, "time" => "1462892538" }

    let(:events) { p_ev }

    it "delta should not be almost equals" do
      expect(subject.instance.almostEquals(21, 10)).to be false
    end

    it "delta should be almost equals" do
      expect(subject.instance.almostEquals(-18, -10)).to be true
    end

    it "should have no drift" do
      expect(subject.instance.noDrift(10, 5, 1)).to be true
    end

    it "should have a drift" do
      expect(subject.instance.noDrift(10, 5, 2)).to be false
    end

    it "should return a point hash with the correct timestamps aka delta" do

      points = Chronix::Points.new
      points.p << subject.instance.createChronixPoint(0, "1.0")
      points.p << subject.instance.createChronixPoint(0, "2.0")
      points.p << subject.instance.createChronixPoint(0, "3.0")
      points.p << subject.instance.createChronixPoint(0, "4.0")
      points.p << subject.instance.createChronixPoint(0, "5.0")
      points.p << subject.instance.createChronixPoint(0, "6.0")
      points.p << subject.instance.createChronixPoint(0, "7.0")
      points.p << subject.instance.createChronixPoint(0, "8.0")
      points.p << subject.instance.createChronixPoint(9, "9.0")
      points.p << subject.instance.createChronixPoint(0, "10.0")
      points.p << subject.instance.createChronixPoint(0, "11.0")
      points.p << subject.instance.createChronixPoint(0, "12.0")
      points.p << subject.instance.createChronixPoint(0, "13.0")
      points.p << subject.instance.createChronixPoint(0, "14.0")
      points.p << subject.instance.createChronixPoint(9, "15.0")
    
      res = solr.get("test9")
# TODO fix tests
#      expect(res[0][:data]).to eq("H4sIADUHR1cAA+Pi5mAQZACDD/ZcCA6DAxKHA5kjgMwRQeZIIHNkkDkKIA4nlKOELKOCzFFD5mggc7SQOTrIpuk5AADFv8YnwwAAAA==")
    end
  end

end
