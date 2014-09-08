# Original is https://github.com/jimweirich/rake/
# Copyright (c) 2003 Jim Weirich
# License: MIT-LICENSE
#
# This is a fork of minirake that ships with mruby.

def mruby?
  RUBY_ENGINE == 'mruby'
end

def minirake_compiled?
  Object.const_defined? :MINIRAKE
end

if mruby?
  def __dir__
    File.dirname __FILE__
  end
end

$: << __dir__

# for cruby
unless mruby?
  require 'getoptlong'
  require 'fileutils'
end

if !minirake_compiled?
  orig_dollar_zero = $0 if mruby?
  require 'ext/misc'
  require 'ext/string'
  require 'meta'
  require 'cloneable'
  require 'file_list'
  $0 = orig_dollar_zero if mruby?
end

FileList = MiniRake::FileList



$conf = {
  chdir: false,
  verbose: true,
  dryrun: false,
  trace: false,
  debug: {
    vars: {}
  },
  main: self
}

def load_fileutils
  mod = mruby? ? FileUtilsSimple : FileUtils

  if $conf[:dryrun]
    $conf[:main].send :include, mod::DryRun
  elsif !$conf[:verbose]
    $conf[:main].send :include, mod
  else
    $conf[:main].send :include, mod::Verbose
  end
end



module MiniRake

  class Task
    TASKS = Hash.new
    RULES = Array.new

    # List of prerequisites for a task.
    attr_reader :prerequisites

    # Source dependency for rule synthesized tasks.  Nil if task was not
    # sythesized from a rule.
    attr_accessor :source

    attr_accessor :desc
    class << self
      attr_accessor :last_desc
    end

    # Create a task named +task_name+ with no actions or prerequisites..
    # use +enhance+ to add actions and prerequisites.
    def initialize(task_name)
      @name = task_name
      @prerequisites = []
      @actions = []

      # get last defined desc, use it & clean the source
      @desc = Task.last_desc
      Task.last_desc = nil
    end

    # Enhance a task with prerequisites or actions.  Returns self.
    def enhance(deps=nil, &block)
      @prerequisites |= deps if deps
      @actions << block if block_given?
      self
    end

    # Name of the task.
    def name
      @name.to_s
    end

    # Invoke the task if it is needed.  Prerequites are invoked first.
    def invoke
      puts "Invoke #{name} (already=[#{@already_invoked}], needed=[#{needed?}])" if $conf[:trace]
      return if @already_invoked
      @already_invoked = true
      prerequisites = @prerequisites.collect{ |n| n.is_a?(Proc) ? n.call(name) : n }.flatten
      prerequisites.each { |n| Task[n].invoke }
      execute if needed?
    end

    # Execute the actions associated with this task.
    def execute
      puts "Execute #{name}" if $conf[:trace]
      self.class.enhance_with_matching_rule(name) if @actions.empty?
      unless $conf[:dryrun]
        @actions.each { |act| act.call(self) }
      end
    end

    # Is this task needed?
    def needed?
      true
    end

    # Timestamp for this task.  Basic tasks return the current time for
    # their time stamp.  Other tasks can be more sophisticated.
    def timestamp
      prerequisites = @prerequisites.collect{ |n| n.is_a?(Proc) ? n.call(name) : n }.flatten
      prerequisites.collect { |n| Task[n].timestamp }.max || Time.now.to_i
    end

    # Class Methods
    class << self

      # Clear the task list.  This cause rake to immediately forget all
      # the tasks that have been assigned.  (Normally used in the unit
      # tests.)
      def clear
        TASKS.clear
        RULES.clear
        Task.last_desc = nil
      end

      # List of all defined tasks.
      def tasks
        TASKS.keys.sort.collect { |tn| Task[tn] }
      end

      # Return a task with the given name.  If the task is not currently
      # known, try to synthesize one from the defined rules.  If no
      # rules are found, but an existing file matches the task name,
      # assume it is a file task with no dependencies or actions.
      def [](task_name)
        task_name = task_name.to_s
        if task = TASKS[task_name]
          return task
        end
        if task = enhance_with_matching_rule(task_name)
          return task
        end
        if File.exist?(task_name)
          return FileTask.define_task(task_name)
        end
        raise "Don't know how to #{MiniRake::Meta::NAME} #{task_name}"
      end

      # Define a task given +args+ and an option block.  If a rule with
      # the given name already exists, the prerequisites and actions are
      # added to the existing task.
      def define_task(args, &block)
        task_name, deps = resolve_args(args)
        lookup(task_name).enhance([deps].flatten, &block)
      end

      # Define a rule for synthesizing tasks.
      def create_rule(args, &block)
        pattern, deps = resolve_args(args)
        pattern = Regexp.new(Regexp.quote(pattern) + '$') if String === pattern
        RULES << [pattern, deps, block]
      end


      # Lookup a task.  Return an existing task if found, otherwise
      # create a task of the current type.
      def lookup(task_name)
        name = task_name.to_s
        TASKS[name] ||= self.new(name)
      end

      # If a rule can be found that matches the task name, enhance the
      # task with the prerequisites and actions from the rule.  Set the
      # source attribute of the task appropriately for the rule.  Return
      # the enhanced task or nil of no rule was found.
      def enhance_with_matching_rule(task_name)
        RULES.each do |pattern, extensions, block|
          if pattern.match(task_name)
            ext = extensions.first
            deps = extensions[1..-1]
            case ext
            when String
              source = task_name.sub(/\.[^.]*$/, ext)
            when Proc
              source = ext.call(task_name)
            else
              raise "Don't know how to handle rule dependent: #{ext.inspect}"
            end
            if File.exist?(source)
              task = FileTask.define_task({task_name => [source]+deps}, &block)
              task.source = source
              return task
            end
          end
        end
        nil
      end

      private

      # Resolve the arguments for a task/rule.
      def resolve_args(args)
        case args
        when Hash
          raise "Too Many Task Names: #{args.keys.join(' ')}" if args.size > 1
          raise "No Task Name Given" if args.size < 1
          task_name = args.keys[0]
          deps = args[task_name]
          deps = [deps] if (String===deps) || (Regexp===deps) || (Proc===deps)
        else
          task_name = args
          deps = []
        end
        [task_name, deps]
      end
    end
  end
end



module MiniRake

  class FileTask < Task
    # Is this file task needed?  Yes if it doesn't exist, or if its time
    # stamp is out of date.
    def needed?
      return true unless File.exist?(name)
      prerequisites = @prerequisites.collect{ |n| n.is_a?(Proc) ? n.call(name) : n }.flatten
      latest_prereq = prerequisites.collect{|n| Task[n].timestamp}.max
      return false if latest_prereq.nil?
      timestamp < latest_prereq
    end

    # Time stamp for file task.
    def timestamp
      File::stat(name.to_s).mtime
    end
  end

  module DSL
    # Declare a basic task.
    def task(args, &block)
      MiniRake::Task.define_task(args, &block)
    end

    # Declare a file task.
    def file(args, &block)
      MiniRake::FileTask.define_task(args, &block)
    end

    # Declare a set of files tasks to create the given directories on
    # demand.
    def directory dir
      path = []
      dir.split(File::SEPARATOR).each do |p|
        path << p
        FileTask.define_task(File.join(*path)) do |t|
          sh "mkdir -p #{t.name}"
        end
      end
    end

    # Declare a rule for auto-tasks.
    def rule(args, &block)
      MiniRake::Task.create_rule(args, &block)
    end

    # Write a message to standard out if verbose is enabled.
    def log(msg)
      print "  " if $conf[:trace] && $conf[:verbose]
      puts msg if $conf[:verbose]
    end

    # Run the system command +cmd+.
    def sh(cmd)
      puts cmd if $conf[:verbose]

      return if $conf[:dryrun]
      system(cmd) or raise "Command raised: [#{cmd}]"
    end

    def desc text
      Task.last_desc = text
    end

    def ec07bc vars
      $conf[:debug][:vars] = vars
    end
  end
end

extend MiniRake::DSL



# Minirake main application object.  When invoking minirake from the
# command line, a App object is created and run.
class App

  RAKEFILES = ['rakefile', 'Rakefile']

  OPTIONS = [
             ['--dry-run',  '-n', GetoptLong::NO_ARGUMENT,
              "Do a dry run without executing actions."],
             ['--help',     '-h', GetoptLong::NO_ARGUMENT,
              "Display this help message."],
             ['--libdir',   '-I', GetoptLong::REQUIRED_ARGUMENT,
              "Include LIBDIR in the search path for required modules."],
             ['--nosearch', '-N', GetoptLong::NO_ARGUMENT,
              "Do not search parent directories for the Rakefile."],
             ['--quiet',    '-q', GetoptLong::NO_ARGUMENT,
              "Do not log messages to standard output."],
             ['--rakefile', '-f', GetoptLong::REQUIRED_ARGUMENT,
              "Use FILE as the rakefile."],
             ['--require',  '-r', GetoptLong::REQUIRED_ARGUMENT,
              "Require MODULE before executing rakefile."],
             ['--prereqs',    '-P', GetoptLong::NO_ARGUMENT,
              "Display the tasks and dependencies, then exit."],
             ['--trace',    '-t', GetoptLong::NO_ARGUMENT,
              "Turn on invoke/execute tracing."],
             ['--verbose',  '-v', GetoptLong::NO_ARGUMENT,
              "Log message to standard output (default)."],
             ['--version', '-V', GetoptLong::NO_ARGUMENT,
              'Display the program version.'],
             ['--directory', '-C', GetoptLong::REQUIRED_ARGUMENT,
              "Change executing directory of rakefiles."],
             ['--printvar', '-A', GetoptLong::REQUIRED_ARGUMENT,
              "Print minirake's idea of the value of VAR, then exit."],
             ['--tasks', '-T', GetoptLong::NO_ARGUMENT,
              "Display tasks with descriptions, then exit."],
            ]

  def initialize
    @rakefile = nil
    @nosearch = false
    @show_tasks = false
    @printvar = []
    @show_desc = false
  end

  # True if one of the files in RAKEFILES is in the current directory.
  # If a match is found, it is copied into @rakefile.
  def have_rakefile
    RAKEFILES.each do |fn|
      if File.exist?(fn)
        @rakefile = fn
        return true
      end
    end
    return false
  end

  def help
    puts "#{File.basename $0} [-f rakefile] {options} targets..."
    puts
    OPTIONS.sort.each do |long, short, mode, desc|
      if mode == GetoptLong::REQUIRED_ARGUMENT
        if desc =~ /\b([A-Z]{2,})\b/
          long = long + "=#{$1}"
        end
      end
      printf "%s, %-20s %s\n", short, long, desc
    end
  end

  # Do the option defined by +opt+ and +value+.
  def do_option(opt, value)
    case opt
    when '--dry-run'
      $conf[:dryrun] = true
      $conf[:trace] = true
    when '--help'
      help
      exit
    when '--libdir'
      $:.push(value)
    when '--nosearch'
      @nosearch = true
    when '--quiet'
      $conf[:verbose] = false
    when '--rakefile'
      RAKEFILES.clear
      RAKEFILES << value
    when '--require'
      require value
    when '--prereqs'
      @show_tasks = true
    when '--trace'
      $conf[:trace] = true
    when '--verbose'
      # $conf[:verbose] is true by default
    when '--version'
      puts "#{MiniRake::Meta::NAME}: #{MiniRake::Meta::VERSION}"
      puts "Compiled: #{minirake_compiled?}"
      puts "Engine: #{RUBY_ENGINE} #{mruby? ? MRUBY_VERSION : RUBY_VERSION}"
      exit
    when '--directory'
      Dir.chdir value
      $conf[:chdir] = true
    when '--printvar'
      @printvar << value
    when '--tasks'
      @show_desc = true
    end
  end

  # Read and handle the command line options.
  def handle_options
    opts = GetoptLong.new(*OPTIONS.collect { |idx| idx[0..-2] })
    opts.each { |opt, value| do_option(opt, value) }
  rescue GetoptLong::Error
    # GetoptLong will still complain independently
    exit 1
  end

  # Display the tasks and dependencies.
  def display_tasks
    MiniRake::Task.tasks.each do |t|
      puts "#{t.class} #{t.name}"
      t.prerequisites.each { |pre| puts "    #{pre}" }
    end
  end

  # Display only tasks with desc.
  def display_desc
    MiniRake::Task.tasks.select do |idx|
      idx.desc
    end.each do |idx|
      folded = idx.desc.scan(/\S.{0,70}\S(?=\s|$)|\S+/) # break a string into an array
      printf "%s\n    %s\n", idx.name, folded.join("\n    ")
    end
  end

  def printvar
    if $conf[:debug][:vars].size == 0
      $stderr.puts "Put the magick line below in the end of a Rakefile & rerun minirake:"
      $stderr.puts
      $stderr.puts 'v={};local_variables[0..-2].each{|i|v[i]=eval(i.to_s)};ec07bc v rescue 1'
      exit 1
    end

    @printvar.each do |var|
      puts "#{var} = #{$conf[:debug][:vars][var.to_sym].inspect}"
    end
  end

  # Run the minirake application.
  def run
    handle_options

    begin
      here = Dir.pwd
      while ! have_rakefile
        Dir.chdir("..")
        if Dir.pwd == here || @nosearch
          raise "No Rakefile found (looking for: #{RAKEFILES.join(', ')})"
        end
        here = Dir.pwd
        $conf[:chdir] = true
      end
      tasks = []
      ARGV.each do |task_name|
        if /^(\w+)=(.*)/.match(task_name)
          ENV[$1] = $2
        else
          tasks << task_name
        end
      end
      puts "(in #{Dir.pwd})" if $conf[:chdir]

      load_fileutils

      # Execute rakefile code
      #
      # TODO: write load_with_context(file, ctx) mrbgem
      load File.realpath @rakefile

      if @show_tasks
        display_tasks
      elsif @show_desc
        display_desc
      elsif @printvar.size != 0
        printvar
      else
        tasks.push("default") if tasks.size == 0
        tasks.each do |task_name|
          MiniRake::Task[task_name].invoke
        end
      end
    rescue Exception => ex
      puts "#{MiniRake::Meta::NAME} aborted!"
      puts ex.inspect
      puts ex.backtrace.join("\n") if $conf[:trace]
      exit 1
    end
  end

end



App.new.run if __FILE__ == MiniRake::Meta::NAME || __FILE__ == $0
