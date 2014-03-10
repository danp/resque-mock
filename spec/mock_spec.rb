require 'resque/mock'

Resque.mock!

class Performer
  def self.queue
    'performings'
  end

  def self.run?
    !!@args
  end

  def self.args
    @args
  end

  def self.runs
    @runs || 0
  end

  def self.perform(*args)
    @runs += 1
    if Hash === (options = args.first)
      if runs_left = options['runs']
        runs_left -= 1
        if runs_left > 0
          Resque.enqueue(self, 'runs' => runs_left)
        end
      end
    end
    @args = args
  end

  def self.reset!
    @args = nil
    @runs = 0
  end
end

class BadPerformer < Performer
  def self.perform(*args)
    raise 'hello'
  end
end

class QueuelessPerformer < Performer
  class << self
    undef :queue
  end
end

describe Resque do
  before { Performer.reset! }

  describe "synchronously" do
    it "ensures the queue can be determined" do
      expect {
        Resque.enqueue(QueuelessPerformer, 'hello', 'there')
      }.to raise_error(Resque::NoQueueError)
    end

    it "performs jobs without delay" do
      Resque.enqueue(Performer, 'hello', 'there')
      Performer.should be_run
      Performer.args.should == ['hello', 'there']
    end

    it "performs jobs with a delay" do
      Resque.should_receive(:sleep).with(5)
      Resque.enqueue_in(5, Performer, 'hello', 'there')
      Performer.should be_run
      Performer.args.should == ['hello', 'there']
    end

    it "can perform more jobs that are queued" do
      Resque.enqueue(Performer, 'runs' => 3)
      Performer.runs.should == 3
    end

    it "roundtrips arguments" do
      Resque.enqueue(Performer, :hello => :there)
      Performer.args.should == [{ 'hello' => 'there' }]
    end
  end

  describe "asynchronously" do
    it "performs jobs without delay" do
      Resque.async do
        Resque.enqueue(Performer, 'hello', 'there')
      end

      Performer.should be_run
      Performer.args.should == ['hello', 'there']
    end

    it "performs jobs with delay" do
      # not immediately sure how to mock this

      Resque.async do
        Resque.enqueue_in(5, Performer, 'hello', 'there')
      end

      Performer.should be_run
      Performer.args.should == ['hello', 'there']
    end

    it "can perform more jobs that are queued" do
      Resque.async { Resque.enqueue(Performer, 'runs' => 3) }
      Performer.runs.should == 3
    end

    it "roundtrips arguments" do
      Resque.async { Resque.enqueue(Performer, :hello => :there) }
      Performer.args.should == [{ 'hello' => 'there' }]
    end

    it "raises errors encountered inside the block" do
      expect { Resque.async { raise 'hello' } }.to raise_error
    end

    it "raises errors encountered by jobs" do
      expect { Resque.async { Resque.enqueue(BadPerformer, 5) } }.to raise_error
    end
    
    it 'clears async flag if errors are raised' do
      Resque.async?.should be_false
      expect { Resque.async { Resque.enqueue(BadPerformer, 5) } }.to raise_error
      Resque.async?.should be_false
    end
  end
  
  describe 'discard' do
    before do
      Resque.discard = true
    end
    
    after do
      Resque.discard = false
    end
    
    it 'does not perform jobs' do
      Resque.enqueue(Performer, 'hello', 'there')
      Performer.should_not be_run
    end
  end
  
  describe 'discard block form' do
    it 'does not perform jobs' do
      Resque.discard { Resque.enqueue(Performer, 'hello', 'there') }
      Performer.should_not be_run
    end
  end
end
