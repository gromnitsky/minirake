def make_tasks
  name = "dynamicTest"
  MiniRake::Task.define_task(name)
  name
end

desc "test task"
task "test" => make_tasks

task :default => "test"
