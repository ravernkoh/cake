class Cake::Target
  getter name
  getter deps
  getter desc

  def initialize(@name : String, @deps : Array(String), @desc : String, &@build : Env ->)
  end

  def build(env : Env) : Bool
    env.name = @name
    env.deps = @deps
    env.modified_deps = [] of String

    rebuild = false

    if Targets::INSTANCE.phony.includes?(@name)
      rebuild = true
    end

    begin
      modification_time = File.info(name).modification_time
    rescue exception : Errno
      rebuild = true
    end

    @deps.each do |dep|
      if target = Targets::INSTANCE.all[dep]?
        if target.build(env)
          rebuild = true
        end
      elsif modification_time
        dep_modification_time = File.info(dep).modification_time
        if dep_modification_time.epoch - modification_time.epoch > env.timeout
          rebuild = true
          env.modified_deps << dep
        end
      end
    end

    unless rebuild
      if env.verbose
        puts "Target #{@name} up to date"
      end
      return false
    end

    if env.verbose
      puts "Building target #{@name}..."
    end

    @build.call(env)
    true
  end
end
