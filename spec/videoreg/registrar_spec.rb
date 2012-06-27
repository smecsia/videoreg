require_relative '../spec_helper'
require 'tmpdir'

describe Videoreg::Registrar do


  it "should clean up old files" do

    tmpdir = Pathname.new(Dir.tmpdir)
    reg = Videoreg::Registrar.new { |c|
      c.storage = tmpdir.to_s
      c.store_max = 5
    }

    (reg.config.store_max + 10).times {
      File.open(tmpdir.join("#{Time.now.to_i}.#{Time.now.usec}.avi").to_s, "w+") { |f| f.write('') }
    }

    lambda {
      reg.clean_old_files!
    }.should change {
      Dir[tmpdir.join('*.avi').to_s].length
    }.to(reg.config.store_max)


    lambda {
      reg.clean_old_files!
    }.should_not change {
      Dir[tmpdir.join('*.avi').to_s].length
    }

  end
end