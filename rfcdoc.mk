#
# Include file that does all the work for building RFCs
#

# The original Makefile can re-assign if sharing rfcdoc repo
RFCDOC_BASE ?= ${rfcdoc}

references_src ?= references.txt
references_xml ?= references.xml

PYANG_BASE ?= ${RFCDOC_BASE}/submodules/pyang
XML2RFC_BASE ?= ${RFCDOC_BASE}/submodules/xml2rfc

# First we do some guessing at the name of files, if not provided
ifeq (,${draft})
possible_drafts = draft-*.xml draft-*.md draft-*.org
draft := $(lastword $(sort $(wildcard ${possible_drafts})))
endif

ifeq (,${examples})
examples = $(wildcard ex-*.xml)
endif
load=$(patsubst ex-%.xml,ex-%.load,${examples})

ifeq (,${std_yang})
std_yang := $(wildcard ietf*.yang)
endif
ifeq (,${ex_yang})
ex_yang := $(wildcard ex*.yang)
endif
yang := ${std_yang} ${ex_yang}

draft_base = $(basename ${draft})
draft_type := $(suffix ${draft})

# Hardcoded paths to tools (in the captive submodule)
XML2RFC ?= ${RFCDOC_BASE}/tools/bin/xml2rfc
OXTRADOC ?= ${RFCDOC_BASE}/tools/bin/oxtradoc
IDNITS ?= ${RFCDOC_BASE}/tools/bin/idnits
PYANG ?= ${RFCDOC_BASE}/tools/bin/pyang
YANG2DSDL ?= ${RFCDOC_BASE}/tools/bin/yang2dsdl

PYANG_PYTHON = env PYTHONPATH=${PYANG_BASE} ${PYANG}

ifeq (,${draft})
$(warning No file named draft-*.md or draft-*.xml or draft-*.org)
$(error Read README.md for setup instructions)
endif

current_ver := $(shell git tag | grep '${output_base}-[0-9][0-9]' | tail -1 | sed -e"s/.*-//")
ifeq "${current_ver}" ""
next_ver ?= 00
else
next_ver ?= $(shell printf "%.2d" $$((1${current_ver}-99)))
endif
output ?= ${output_base}-${next_ver}

.PHONY: latest submit clean validate

submit: ${output}.txt

html: ${output}.html

latest: ${output}.txt

idnits: ${output}.txt
	${IDNITS} $<

clean:
	-rm -f ${output_base}-[0-9][0-9].* ${references_xml} ${load}
	-rm -f *.dsrl *.rng *.sch ${draft_base}.fxml

%.load: %.xml
	 cat $< | awk -f fix-load-xml.awk > $@
.INTERMEDIATE: ${load}

example-system.oper.yang: example-system.yang
	grep -v must $< > $@
.INTERMEDIATE: example-system.oper.yang

validate: validate-std-yang validate-ex-yang validate-ex-xml

validate-std-yang:
	${PYANG_PYTHON} --ietf --max-line-length 69 ${std_yang}

validate-ex-yang:
	${PYANG_PYTHON} --canonical --max-line-length 69 ${ex_yang}

validate-ex-xml: ietf-origin.yang example-system.yang \
	example-system.oper.yang
	${YANG2DSDL} -j -t data -v ex-intended.xml $< example-system.yang
	${YANG2DSDL} -j -t data -v ex-oper.xml $< example-system.oper.yang

${references_xml}: ${references_src}
	${OXTRADOC} -m mkback $< > $@

${output}.xml: ${draft} ${references_xml} ${trees} ${load} ${yang}
	${OXTRADOC} -m outline-to-xml -n "${output}" $< > $@

${output}.txt: ${output}.xml
	${XML2RFC} $< -o $@ --text

%.tree: %.yang
	${PYANG_PYTHON} -f tree --tree-line-length 68 $< > $@

${output}.html: ${draft} ${references_xml} ${trees} ${load} ${yang}
	@echo "Generating $@ ..."
	${OXTRADOC} -m html -n "${output}" $< > $@

new-tag: ${output}.txt
	@echo Tagging with ${output}...
	git tag ${output}

update-rfcdoc:
	@echo Updating rfcdoc ...
	cd ${RFCDOC_BASE}; git pull -v
