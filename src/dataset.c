/*
 * Copyright 2017 Patrick O. Perry.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <assert.h>
#include <inttypes.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <Rdefines.h>
#include "corpus/src/render.h"
#include "corpus/src/table.h"
#include "corpus/src/text.h"
#include "corpus/src/token.h"
#include "corpus/src/symtab.h"
#include "corpus/src/data.h"
#include "corpus/src/datatype.h"
#include "rcorpus.h"

#define DATASET_TAG install("corpus::dataset")


static void free_dataset(SEXP sdataset)
{
        struct dataset *d = R_ExternalPtrAddr(sdataset);
	if (d) {
		free(d->rows);
		free(d);
	}
}


SEXP alloc_dataset(struct schema *schema, int type_id, struct data *rows,
		   R_xlen_t nrow, SEXP prot)
{
	SEXP sdata, sclass;
	struct dataset *obj;

	if (!(obj = malloc(sizeof(*obj)))) {
		free(rows);
		error("failed allocating memory (%zu bytes)", sizeof(*obj));
	}
	obj->schema = schema;
	obj->rows = rows;
	obj->nrow = nrow;
	obj->type_id = type_id;

	if (type_id < 0) {
		obj->kind = DATATYPE_ANY;
	} else {
		obj->kind = schema->types[type_id].kind;
	}

	PROTECT(sdata = R_MakeExternalPtr(obj, DATASET_TAG, prot));
	R_RegisterCFinalizerEx(sdata, free_dataset, TRUE);

	PROTECT(sclass = allocVector(STRSXP, 1));
	SET_STRING_ELT(sclass, 0, mkChar("dataset"));
	setAttrib(sdata, R_ClassSymbol, sclass);

	UNPROTECT(2);
	return sdata;
}


int is_dataset(SEXP sdata)
{
	return ((TYPEOF(sdata) == EXTPTRSXP)
		&& (R_ExternalPtrTag(sdata) == DATASET_TAG));
}


struct dataset *as_dataset(SEXP sdata)
{
	if (!is_dataset(sdata))
		error("invalid 'dataset' object");
	return R_ExternalPtrAddr(sdata);
}


SEXP dim_dataset(SEXP sdata)
{
	SEXP dims;
	const struct dataset *d = as_dataset(sdata);
	const struct datatype *t;
	const struct datatype_record *r;

	if (d->kind != DATATYPE_RECORD) {
		return R_NilValue;
	}

	t = &d->schema->types[d->type_id];
	r = &t->meta.record;

	if (d->nrow > INT_MAX) {
		PROTECT(dims = allocVector(REALSXP, 2));
		REAL(dims)[0] = (double)d->nrow;
		REAL(dims)[1] = (double)r->nfield;
	} else {
		PROTECT(dims = allocVector(INTSXP, 2));
		INTEGER(dims)[0] = d->nrow;
		INTEGER(dims)[1] = (int)r->nfield;
	}
	UNPROTECT(1);

	return dims;
}


SEXP length_dataset(SEXP sdata)
{
	const struct dataset *d = as_dataset(sdata);

	if (d->kind == DATATYPE_RECORD) {
		return R_NilValue;
	}

	if (d->nrow > INT_MAX) {
		return ScalarReal((double)d->nrow);
	} else {
		return ScalarInteger((int)d->nrow);
	}
}


SEXP names_dataset(SEXP sdata)
{
	SEXP names, str;
	const struct dataset *d = as_dataset(sdata);
	const struct datatype *t;
	const struct datatype_record *r;
	const struct text *name;
	int i;

	if (d->kind != DATATYPE_RECORD) {
		return R_NilValue;
	}

	t = &d->schema->types[d->type_id];
	r = &t->meta.record;

	PROTECT(names = allocVector(STRSXP, r->nfield));
	for (i = 0; i < r->nfield; i++) {
		name = &d->schema->names.types[r->name_ids[i]].text;
		str = mkCharLenCE((char *)name->ptr, TEXT_SIZE(name), CE_UTF8);
		SET_STRING_ELT(names, i, str);
	}

	UNPROTECT(1);
	return names;
}


SEXP datatype_dataset(SEXP sdata)
{
	SEXP str, ans;
	const struct dataset *d = as_dataset(sdata);
	struct render r;

	if (render_init(&r, ESCAPE_NONE) != 0) {
		error("memory allocation failure");
	}
	render_set_tab(&r, "");
	render_set_newline(&r, " ");

	render_datatype(&r, d->schema, d->type_id);
	if (r.error) {
		render_destroy(&r);
		error("memory allocation failure");
	}

	PROTECT(ans = allocVector(STRSXP, 1));
	str = mkCharLenCE(r.string, r.length, CE_UTF8);
	SET_STRING_ELT(ans, 0, str);

	render_destroy(&r);
	UNPROTECT(1);
	return ans;
}


SEXP datatypes_dataset(SEXP sdata)
{
	SEXP types, str, names;
	const struct dataset *d = as_dataset(sdata);
	const struct datatype *t;
	const struct datatype_record *rec;
	struct render r;
	int i;

	if (d->kind != DATATYPE_RECORD) {
		return R_NilValue;
	}

	PROTECT(names = names_dataset(sdata));

	t = &d->schema->types[d->type_id];
	rec = &t->meta.record;

	if (render_init(&r, ESCAPE_NONE) != 0) {
		error("memory allocation failure");
	}
	render_set_tab(&r, "");
	render_set_newline(&r, " ");

	PROTECT(types = allocVector(STRSXP, rec->nfield));
	for (i = 0; i < rec->nfield; i++) {
		render_datatype(&r, d->schema, rec->type_ids[i]);
		if (r.error) {
			render_destroy(&r);
			error("memory allocation failure");
		}
		str = mkCharLenCE(r.string, r.length, CE_UTF8);
		SET_STRING_ELT(types, i, str);
		render_clear(&r);
	}
	setAttrib(types, R_NamesSymbol, names);

	render_destroy(&r);
	UNPROTECT(2);
	return types;
}


SEXP print_dataset(SEXP sdata)
{
	SEXP str, ans;
	const struct dataset *d = as_dataset(sdata);
	struct render r;

	if (render_init(&r, ESCAPE_CONTROL) != 0) {
		error("memory allocation failure");
	}

	render_datatype(&r, d->schema, d->type_id);
	if (r.error) {
		render_destroy(&r);
		error("memory allocation failure");
	}

	if (d->kind == DATATYPE_RECORD) {
		Rprintf("JSON dataset with %"PRIu64" rows"
			" of the following type:\n%s\n",
			(uint64_t)d->nrow, r.string);
	} else {
		Rprintf("JSON dataset with %"PRIu64" rows"
			" of type %s\n", (uint64_t)d->nrow, r.string);
	}

	render_destroy(&r);
	return sdata;
}