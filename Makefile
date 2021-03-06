BENCHES = $(wildcard */)

OCAMLOPT = ocamlopt.opt
OCAMLDEP = ocamldep.opt

ifdef GCSTATS
  MAINSRC = main_gcstats.ml
  LINK = unix.cmxa
else
  MAINSRC = main_nogcstats.ml
  LINK =
endif

all: $(BENCHES:/=.opt)


all-gcstats: $(BENCHES:/=-gcstats.opt)

%.opt: $(MAINSRC) %/*.ml
	ulimit -s 98304; $(OCAMLOPT) $(LINK) -I $* `$(OCAMLDEP) -sort $*/*.ml` $< -o $@
# Huge stack is required to compile k-means

.PHONY: clean
clean:
	rm -f *.cm* *.o *.opt *-gcstats.opt */*.cm* */*.o
