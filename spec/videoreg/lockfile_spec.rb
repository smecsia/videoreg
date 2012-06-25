require_relative '../spec_helper'
require 'tempfile'


describe Videoreg::Lockfile do

  it "should create lockfile " do

    PID = 12345
    tempfile = Tempfile.new('lockfile')
    lock_path = tempfile.path
    tempfile.unlink
    g = Videoreg::Lockfile.new(lock_path)
    g.lock(PID).should be_true
    g.verify.should be_true
    h = Videoreg::Lockfile.new(lock_path)
    h.lock.should be_false
    h.verify.should be_false
    h.release.should be_false
    g.verify.should be_true
    g.lockcode.should == PID.to_s
    g.release.should be_true
    File.exists?(lock_path).should be_false
  end

end