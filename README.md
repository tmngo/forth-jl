# forth-jl

A simple Forth interpreter.

## Usage

At the command line:

``` shell
# Start an interactive prompt. Enter an empty line to exit.
julia forth.jl

# Run code from a file.
julia forth.jl ./examples/print.4th
```

## References

* [Wikipedia](https://en.wikipedia.org/wiki/Forth_(programming_language)): Code examples, representing code.
* [Easy Forth](https://skilldrick.github.io/easyforth/): Exploring how Forth works, common predefined words, testing code.
* [Bootstrapping a Forth in 40 lines of Lua code](http://angg.twu.net/miniforth-article.html): Representing code.
* [jonesforth](https://github.com/nornagon/jonesforth/blob/master/jonesforth.S): Branching, defining words.
* [Hacker News](https://news.ycombinator.com/item?id=13082825): Branching, defining words, immediate words.
