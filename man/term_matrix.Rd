\name{term_matrix}
\alias{term_frame}
\alias{term_matrix}
\title{Term Frequency Tabulation}
\description{
    Tokenize a set of texts and compute a term frequency matrix or data frame.
}
\usage{
    term_matrix(x, filter = token_filter(), weights = NULL,
                ngrams = NULL, select = NULL, group = NULL,
                transpose = FALSE)

    term_frame(x, filter = token_filter(), weights = NULL,
               ngrams = NULL, select = NULL, group = NULL)
}
\arguments{
    \item{x}{a text vector to tokenize.}

    \item{filter}{a token filter specifying the tokenization rules.}

    \item{weights}{a numeric vector the same length of \code{x} assigning
        weights to each text, or \code{NULL} for unit weights.}

    \item{ngrams}{an integer vector of n-gram lengths to include, or
        \code{NULL} to use the \code{select} argument to determine the
        n-gram lengths.}

    \item{select}{a character vector of terms to count, or \code{NULL} to
        count all terms that appear in \code{x}.}

    \item{group}{if non-\code{NULL}, a factor, character string, or
        integer vector the same length of \code{x} specifying the grouping
        behavior.}

    \item{transpose}{a logical value indicating whether to transpose the
        result, putting terms as rows instead of columns.}
}
\details{
    \code{term_matrix} tokenizes a set of texts and computes the occurrence
    counts for each term. If \code{weights} is non-\code{NULL}, then each
    token in text \code{i} increments the count for the corresponding terms
    by \code{weights[i]}; otherwise, each appearance increments the count
    by one.

    If \code{ngrams} is non-\code{NULL}, then multi-type n-grams are
    included in the output for all lengths appearing in the \code{ngrams}
    argument. If \code{ngrams} is \code{NULL} but \code{select} is
    non-\code{NULL}, then all n-grams appearing in the \code{select} set
    are included. If both \code{ngrams} and \code{select} are \code{NULL},
    then only unigrams (single type terms) are included.

    If \code{group} is \code{NULL}, then the output has one set of term
    counts for each input text. Otherwise, we convert \code{group} to
    a \code{factor} and compute one set of term counts for each level.
    Texts with \code{NA} values for \code{group} get skipped.
}
\value{
    \code{term_matrix} with \code{transpose = FALSE} returns a sparse matrix
    in \code{"dgCMatrix"} format with one column for each term and one row for
    each input text or (if \code{group} is non-\code{NULL}) for each grouping
    level.  If \code{filter$select} is non-\code{NULL}, then the column names
    will be equal to \code{filter$select}. Otherwise, the columns are assigned
    in arbitrary order.

    \code{term_matrix} with \code{transpose = TRUE} returns the transpose of
    the term matrix, in \code{"dgCMatrix"} format.

    \code{term_frame} with \code{group = NULL} returns a data frame with one
    row for each entry of the term matrix, and columns \code{"text"},
    \code{"term"}, and \code{"count"} giving the text ID, term, and count. If
    \code{names(as_text(x))} is non-\code{NULL}, then the text ID is taken
    as its name; otherwise, the text ID is an integer giving its row index
    in \code{x}.

    \code{term_frame} with \code{group} non-\code{NULL} behaves similarly,
    but the result instead has columns named \code{"group"}, \code{"term"},
    and \code{"count"}, with \code{"group"} giving the grouping level, as
    a character string.
}
\seealso{
    \code{\link{tokens}}, \code{\link{term_counts}}.
}
\examples{
    text <- c("A rose is a rose is a rose.",
              "A Rose is red, a violet is blue!",
              "A rose by any other name would smell as sweet.")
    term_matrix(text)

    # select certain terms
    term_matrix(text, select = c("rose", "red", "violet", "sweet"))

    # specify a grouping factor
    term_matrix(text, group = c("Good", "Bad", "Good"))

    # weight the texts
    term_matrix(text, weights = c(1, 2, 10),
                group = c("Good", "Bad", "Good"))

    # include higher-order n-grams
    term_matrix(text, ngrams = 1:3)

    # select certain multi-type terms
    term_matrix(text, select = c("a rose", "a violet", "sweet", "smell"))

    # transpose the result
    term_matrix(text, ngrams = 1:2, transpose = TRUE)[1:10, ] # first 10 rows

    # data frame
    head(term_frame(text), n = 10) # first 10 rows

    # with grouping
    term_frame(text, group = c("Good", "Bad", "Good"))

    # taking names from the input
    term_frame(c(a = "One sentence.", b = "Another", c = "!!"))
}
