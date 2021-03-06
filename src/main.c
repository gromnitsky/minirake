#include <mruby.h>
#include <mruby/irep.h>
#include <mruby/proc.h>
#include <mruby/string.h>
#include <mruby/variable.h>
#include <mruby/dump.h>
#include <mruby/array.h>

extern uint8_t bytecode_deps[];
extern uint8_t bytecode_main[];

static void
create_argv(mrb_state *mrb, int argc, char **argv)
{
	mrb_value ARGV = mrb_ary_new_capa(mrb, argc);
	int idx;
	// skip argv[0]
	for (idx = 1; idx < argc; ++idx) {
		mrb_ary_push(mrb, ARGV, mrb_str_new_cstr(mrb, argv[idx]));
	}
	mrb_define_global_const(mrb, "ARGV", ARGV);

	mrb_sym zero_sym = mrb_intern_lit(mrb, "$0");
	mrb_gv_set(mrb, zero_sym, mrb_str_new_cstr(mrb, argv[0]));
}

static void
create_minirake_const(mrb_state *mrb)
{
	mrb_value val = mrb_bool_value(TRUE);
	mrb_define_global_const(mrb, "MINIRAKE", val);
}


int
main(int argc, char **argv)
{
	int status = 0;

	mrb_state *mrb = mrb_open();
	create_argv(mrb, argc, argv);
	create_minirake_const(mrb);

	uint8_t *list[] = {bytecode_deps, bytecode_main, NULL};
	uint8_t **p = list;
	while (*p) {
		// read & execute compiled symbols
		mrb_irep *irep = mrb_read_irep(mrb, *p);
		mrb_value r = mrb_run(mrb, mrb_proc_new(mrb, irep), mrb_top_self(mrb));

		// check for raised exceptions
		if (mrb->exc) {
			r = mrb_funcall(mrb, mrb_obj_value(mrb->exc), "inspect", 0);
			fprintf(stderr, "Error: %s\n", RSTRING_PTR(r));
			status = 1;
		}

		++p;
	}

	mrb_close(mrb);
	return status;
}
