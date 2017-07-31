draft = README.org
output_base = rfcdoc
output = rfcdoc
examples =
trees =
std_yang = 
ex_yang =

rfcdoc = .
include ${rfcdoc}/rfcdoc.mk

GH_PAGES_DIR = gh-pages/
get-gh-pages:
	git clone https://github.com/Juniper/${PACKAGE_NAME}.git \
		gh-pages -b gh-pages

DOCS = ${output}.{txt,html,xml}

upload-docs: submit html
	@-[ -d ${GH_PAGES_DIR} ] \
		&& echo "Updating manual on gh-pages ..." \
		&& cp ${DOCS} ${GH_PAGES_DIR} \
		&& (cd ${GH_PAGES_DIR} \
			&& git commit -m 'new docs' ${DOCS} \
			&& git push origin gh-pages ) ; true
