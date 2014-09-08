# Mruby & Self-Contained Minirake

mruby repo contains an ultra lightweight version of Rake, called
minirake. Unfortunately it has a couple of bugs + depends on full
version of Ruby w/ stdlib.

I thought that it'll be nice to have rake that doesn't require any
Rubies installed.  W/ mruby it's possible to produce standalone
executables (albeit somewhat tricky).

Original Rake has grown fat over the years & it's a quite big program
now. Porting it to mruby is a daunting task. But if you just want
something that is syntactically nicer than GNU Make & works w/o any
dependencies, try minirake. :blue_heart: :yellow_heart:

*This is an experiment. Do some tests before using it in your daily
 tasks.*

```
$ ./minirake -h
minirake [-f rakefile] {options} targets...

-C, --directory          Change executing directory of rakefiles.
-n, --dry-run            Do a dry run without executing actions.
-h, --help               Display this help message.
-I, --libdir=LIBDIR      Include LIBDIR in the search path for required modules.
-N, --nosearch           Do not search parent directories for the Rakefile.
-P, --prereqs            Display the tasks and dependencies, then exit.
-A, --printvar=VAR       Print minirake's idea of the value of VAR, then exit.
-q, --quiet              Do not log messages to standard output.
-f, --rakefile=FILE      Use FILE as the rakefile.
-r, --require=MODULE     Require MODULE before executing rakefile.
-T, --tasks              Display tasks with descriptions, then exit.
-t, --trace              Turn on invoke/execute tracing.
-v, --verbose            Log message to standard output (default).
-V, --version            Display the program version.
```

The idea of `-A` option comes from FreeBSD make (it's actually called
`-V` there).


## Enhancements To MRuby Minirake

* `File.fnmatch`
* `Dir.glob`
* `FileList`
* `String.pathmap`
* Directory targets
* General tasks can depend on file tasks
* `desc` command
* `-A` CLO
* `FileUtils` (look [here](https://github.com/gromnitsky/mruby-fileutils-simple) for caveats)
* Works w/ mruby & cruby

## Requirements

* `gem install ruby_require_inline`
* Linux


## Mruby Compilation

This is a required step before creating minirake executable.

1. Edit `mruby/minirake.gembox` if you want.

2. Run

		$ (cd mruby && rake COMMIT=)

It will clone mruby repo, add a link to our custom gembox, patch mrbc &
build mruby. If build fails, run

	$ (cd mruby && rake clean)
	$ (cd mruby && rake)

E.g. remove `COMMIT=` string completely or add a valid commit id to it.

*You cannot compile minirake against another cozy version of mruby. Only
patched & w/ the custom gembox version will fly.*


## Minirake compilation

	$ cd src
	$ rake

& run `minirake -h`.


## BUGS

* No multitask (parallel prerequisites) support.
* No namespaces.
* No task w/ arguments (make-style `minirake foo BAR=baz` args _are_
  supported).
* Doesn't work in Windows.


## License

MIT.
