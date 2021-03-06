#  Copyright 2017 Patrick O. Perry.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


abbreviations <- function(kind = "english")
{
    wordlist("abbreviations", kind, function(k) .Call(C_abbreviations, k))
}


stopwords <- function(kind = "english")
{
    wordlist("stopwords", kind, function(k) .Call(C_stopwords, k))
}


wordlist <- function(type, kind, call)
{
    kind <- as_kind(type, kind)

    words <- character()
    for (k in kind) {
        wk <- call(k)
        words <- c(words, wk)
    }

    if (length(words) == 0) {
        return(NULL)
    }

    words <- sort(unique(words))
    words
}
