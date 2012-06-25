module Videoreg
  #
  #  Lockfile.rb  --  Implement a simple lock file method
  #
  class Lockfile
    attr_accessor :lockfile

    KEY_LENGTH = 80
    @lockcode = ""

    def initialize(lckf)
      @lockfile = lckf
    end

    def lock(initial_lockcode = nil)
      @initial_lockcode = initial_lockcode
      if File.exists?(@lockfile)
        return false
      else
        create
        ## verify that we indeed did get the lock
        verify
      end
    end

    def verify
      if not File.exists?(@lockfile)
        return false
      end
      if readlock == @lockcode.to_s
        return true
      else
        return false
      end
    end

    def lockcode
      readlock
    end

    def release
      if self.verify
        begin
          File.delete(@lockfile)
          @lockcode = ""
        rescue Exception => e
          return false
        end
        return true
      else
        return false
      end
    end

    def get_or_create_key
      @initial_lockcode || create_key
    end

    def create_key
      alpha = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
      return (0..KEY_LENGTH).map { alpha[rand(alpha.length)] }.join
    end

    def finalize(id)
      #
      # Ensure lock file is erased when object dies before being released
      #
      File.delete(@lockfile)
    end

    ##-----------------##
    private
    ##-----------------##

    def create
      @lockcode = get_or_create_key
      begin
        g = File.open(@lockfile, "w")
        g.write @lockcode
        g.close
      rescue Exception => e
        return false
      end
      return true
    end

    def readlock
      code = ""
      begin
        g = File.open(@lockfile, "r")
        code = g.read
        g.close
      rescue
        return ""
      end
      return code
    end

  end
end