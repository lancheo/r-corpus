context("text_names")


test_that("`names` should be NULL for new text", {
    x <- as_text("ABC")
    expect_equal(names(x), NULL)
})


test_that("`names<-` should work on text", {
    x <- as_text(LETTERS)
    names(x) <- rev(LETTERS)
    expect_equal(names(x), rev(LETTERS))
})


test_that("`as_text` should not drop names", {
    x <- as_text(c(a="1", b="2"))
    expect_equal(names(x), c("a", "b"))
})


test_that("`all.equal` should test names", {
    x <- as_text(1:3)
    y <- x
    names(y) <- c("a", "b", "c")
    expect_equal(all.equal(x, y), "names for current but not for target")
    expect_equal(all.equal(y, x), "names for target but not for current")
})


test_that("`as_text` should not drop names", {
    x <- as_text(c(foo="hello"))
    y <- as_text(x)

    expect_equal(y, as_text(c(foo="hello")))
})


test_that("`as_text` should drop attributes", {
    x <- as_text("hello")
    attr(x, "foo") <- "bar"
    y <- as_text(x)

    expect_equal(y, as_text("hello"))
})


test_that("`as_text` should drop attributes for JSON objects", {
    file <- tempfile()
    writeLines('{"text": "hello"}', file)
    x <- read_ndjson(file)$text

    attr(x, "foo") <- "bar"
    y <- as_text(x)

    expect_equal(y, as_text("hello"))
})


test_that("`names<-` should not modify copies", {
    x <- as_text(1:3)
    y <- x
    names(y) <- c("a", "b", "c")
    expect_equal(names(x), NULL)
    expect_equal(names(y), c("a", "b", "c"))
})


test_that("`names<-` should preserve attributes", {
    x <- as_text(1:3)
    attr(x, "foo") <- "bar"
    names(x) <- c("a", "b", "c")
    expect_equal(names(x), c("a", "b", "c"))
    expect_equal(attr(x, "foo"), "bar")
})


test_that("`names<-` should allow NA", {
    x <- as_text(1:3)
    names(x) <- c("a", NA, "b")
    expect_equal(names(x), c("a", NA, "b"))
})


test_that("`names<-` should allow duplicates", {
    x <- as_text(1:3)
    names(x) <- c("a", "b", "a")
    expect_equal(names(x), c("a", "b", "a"))
})
