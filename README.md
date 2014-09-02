# Mruby & Self-Contained Minirake

mruby repo contains an ultra lightweight version of Rake, called
minirake. Unfortunately it depends on full version of Ruby & doesn't
work with mruby.

I thought that it'll be nice to have rake that doesn't require any
Rubies installed.  With mruby it's possible to produce stand-alone
executables (albeit somewhat tricky).

Original Rake has grown fat over the years & it's a quite big program
now. Porting it to mruby is in my TODO list (near the end of it). But if
you just want something that is syntactically nicer than GNU Make &
works w/o any dependencies, try minirake.

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
-t, --trace              Turn on invoke/execute tracing.
-v, --verbose            Log message to standard output (default).
-V, --version            Display the program version.
```

## Requirements

* `gem install ruby_require_inline`
* Linux


## Compilation

This is a required step before creating minirake executable:

	$ (cd mruby && rake COMMIT=)

It will clone mruby repo, add a link to our custom gembox to it & build
mruby. If build fails, remove `COMMIT=` string completely or add a valid
commit id to it.

Then

	$ cd src
	$ rake

& run `minirake --help`.


## BUGS

* `FileUtils` is missing (use `sh "blah-blah"`).
* No parallel jobs.
* No multitask support.
* `desc` is a no-op.


## License

MIT.
