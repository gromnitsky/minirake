def make_tasks
  name = "dynamicTest"
  MiniRake::Task.define_task(name).desc = 'a desc for a dynamic task'
  name
end

desc "default task"
task :default => "test"

task "test" => make_tasks
