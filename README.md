# Mruby & Self-Contained Minirake

mruby repo contains an ultra lightweight version of Rake, called
minirake. Unfortunately it depends on full version of Ruby & doesn't
work with mruby.

JFF it's nice to have rake that doesn't require any Rubies installed.
With mruby it's possible to produce stand-alone executables (albeit
somewhat tricky).

Original Rake has grown fat over the years & it's a quite big program
now. Porting it to mruby is in my TODO list (near the end of it). But if
you just want something that is syntactically nicer than GNU Make &
works w/o any dependencies, try minirake.

*This is an experiment. Do some tests before using it in your daily
 tasks.*


## Requirements

* `gem install ruby_require_inline`
* Linux


## Compilation

This is a required step before creating minirake executable:

	$ (cd mruby && rake)

It will clone mruby repo, add a link to our custom gembox to it & build
mruby. If build fails, edit `Rakefile` to remove/add a mruby commit id.

Then

	$ cd src
	$ rake

& run `minirake --help`.


## BUGS

* `FileList` is missing (use plain `Dir.glob` as a replacement).
* `FileUtils` is missing (use `sh "blah-blah"`).
* No parallel jobs.
* No multitask support.
* `desc` is a no-op.


## License

MIT.
