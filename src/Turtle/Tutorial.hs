{-# OPTIONS_GHC -fno-warn-unused-imports #-}

{-| Use @turtle@ if you want to write light-weight and maintainable shell
    scripts.

    @turtle@ embeds shell scripting directly within Haskell for three reasons:

    * Haskell code is easy to refactor and maintain because Haskell is
      statically typed

    * Haskell is syntactically lightweight, thanks to global type inference

    These two features make Haskell ideal for scripting.

    This tutorial introduces how to use the @turtle@ library for scripting and
    this tutorial assumes no prior knowledge of Haskell, but does assume prior
    knowledge of Bash or a similar shell scripting language.
-}

module Turtle.Tutorial (
    -- * Introduction
    -- $introduction

    -- * Comparison
    -- $compare

    -- * Subroutines
    -- $do

    -- * Types
    -- $types

    -- * Shell
    -- $shell

    -- * Type signatures
    -- $signatures

    -- * System
    -- $system
    ) where

import Turtle

-- $introduction
-- Let's translate some simple Bash scripts to Haskell and work our way up to
-- more complex scripts.  Here is an example \"Hello, world!\" script written
-- in both languages:
--
-- >#!/usr/bin/env runhaskell           -- #!/bin/bash
-- >                                    --
-- >{-# LANGUAGE OverloadedStrings #-}  --
-- >                                    --
-- >import Turtle                       --
-- >                                    --
-- >main = echo "Hello, world!"         -- echo Hello, world!
--
-- In Haskell you can use @--@ to comment out the rest of a line.  The above
-- example uses comments to show the equivalent Bash script side-by-side with
-- the Haskell script.
--
-- You can execute the above code by saving it to the file @example.hs@, making
-- the file executable, and then running the file:
--
-- >$ chmod u+x example.hs 
-- >$ ./example.hs
-- >Hello, world!
--
-- If you delete the first line of the program, you can also compile the above
-- code to generate a native executable:
--
-- >$ ghc -O2 example.hs  # -O2 turns on all optimizations
-- >$ ./example
-- >Hello, world!
--
-- You can even run Haskell code interactively using @ghci@, which is an
-- interactive REPL for Haskell code.  You can either use @ghci@ by itself:
--
-- >$ ghci
-- >...
-- >Prelude> :set -XOverloadedStrings
-- >Prelude> import Turtle
-- >Prelude Turtle> echo "Hello, world!"
-- >Hello, world!
-- >Prelude Turtle> :quit
-- >$
--
-- ... or you can load Haskell code into @ghci@, which will bring all top-level
-- values from that program into scope:
--
-- >$ ghci example.hs
-- >...
-- >[1 of 1] Compiling Main             ( example.hs, interpreted )
-- >Ok, modules loaded: Main.
-- >*Main> main
-- >Hello, world!
-- >*Main> :quit
-- >$

-- $compare
-- You'll already notice a few differences between the Haskell code and Bash
-- code.
--
-- First, the Haskell code requires two additional lines of overhead to import
-- the @turtle@ library and enable overloading of string literals.  This
-- overhead is mostly unavoidable.
--
-- Second, the Haskell `echo` explicitly quotes its string argument whereas the
-- Bash @echo@ does not.  In Bash every token is a string by default and you
-- distinguish variables by prepending a dollar sign to them.  In Haskell,
-- every token is a variable by default and you distinguish strings by quoting
-- them.  The following example highlights the difference:
--
-- >#!/usr/bin/env runhaskell           -- #!/bin/bash
-- >                                    --
-- >{-# LANGUAGE OverloadedStrings #-}  --
-- >                                    --
-- >import Turtle                       --
-- >                                    --
-- >str = "Hello!"                      --STR=Hello!
-- >                                    --
-- >main = echo str                     --echo $STR
--
-- Third, you have to explicitly assign a subroutine to @main@ to specify which
-- subroutine to run when your program begins.  This is because Haskell lets you
-- define things out of order.  For example, we could have written our original
-- program this way instead:
--
-- >#!/usr/bin/env runhaskell
-- >
-- >{-# LANGUAGE OverloadedStrings #-}
-- >
-- >import Turtle
-- >
-- >main = echo str
-- >
-- >str = "Hello, world!"
--
-- Notice how the above program defines @str@ after @main@, which is valid.
-- Haskell does not care in what order you define top-level values and functions
-- (using the @=@ sign).
--
-- The top level of a Haskell program only permits definitions.  For example, if
-- you were to insert a statement at the top-level:
--
-- >#!/usr/bin/env runhaskell
-- >
-- >{-# LANGUAGE OverloadedStrings #-}
-- >
-- >import Turtle
-- >
-- >echo "Hello, world!"
--
-- ... then you would get this error when you tried to run your program:
--
-- >example.hs:7:1: Parse error: naked expression at top level

-- $do
-- You can use @do@ notation to create a subroutine that runs more than one
-- command:
--
-- >#!/usr/bin/env runhaskell           -- #!/bin/bash
-- >                                    --
-- >{-# LANGUAGE OverloadedStrings #-}  --
-- >                                    --
-- >import Turtle                       --
-- >                                    --
-- >main = do                           --
-- >    echo "Line 1"                   -- echo Line 1
-- >    echo "Line 2"                   -- echo Line 2
-- 
-- >$ ./example.hs
-- >Line 1
-- >Line 2
--
-- Some commands can return a value, and you can bind the result of a command
-- using the @<-@ symbol.  For example, the following program prints the
-- creation time of the current working directory by storing two intermediate
-- results:
--
-- >#!/usr/bin/env runhaskell  -- #!/bin/bash
-- >                           --
-- >import Turtle              --
-- >                           --
-- >main = do                  --
-- >    dir  <- pwd            -- DIR=$(pwd)
-- >    time <- datefile dir   -- TIME=$(date -r $DIR)
-- >    print time             -- echo $TIME
--
-- >$ ./example.hs
-- >2015-01-24 03:40:31 UTC
--
-- @do@ notation lets you combine smaller subroutines into larger subroutines.
-- For example, we could refactor the above code to split the first two commands
-- into their own smaller subroutine and then invoke that subroutine within a
-- larger subroutine:
--
-- >#!/usr/bin/env runhaskell   -- #!/bin/bash
-- >                            --
-- >import Turtle               --
-- >                            --
-- >datePwd = do                -- datePwd() {
-- >    dir    <- pwd           --     DIR=$(pwd)
-- >    result <- datefile dir  --     RESULT=$(date -r $DIR)
-- >    return result           --     echo $RESULT
-- >                            -- }
-- >main = do                   --
-- >    time <- datePwd         -- TIME=$(datePwd)
-- >    print time              -- echo $TIME
--
-- We can guarantee that this refactored program returns the exact same result:
--
-- >$ ./example.hs
-- >2015-01-24 03:40:31 UTC
--
-- We can also simplify the code a little bit because @do@ notation implicitly
-- returns the value of the last command within a subroutine.  We can use this
-- trick to simplify both the Haskell and Bash code:
--
-- >datePwd = do      -- datePwd() {
-- >    dir <- pwd    --     DIR=$(pwd)
-- >    datefile dir  --     date -r $DIR
-- >                  -- }
--
-- However, keep in mind that the `return` statement is something of a misnomer
-- since it does not break or exit from the surrounding subroutine.  All it
-- does is bind its argument as its result:
--
-- >do x <- return expr
-- >   command x
-- >
-- >-- Same as:
-- >command expr
--
-- In fact, Haskell lets you use the @=@ sign for this common case where you
-- just want to create a new name for an expression:
--
-- >do let x = expr
-- >   command x
-- >
-- >-- Same as:
-- >command expr
--
-- Also, for a subroutine with a single command, you can omit the @do@:
--
-- >main = do echo "Hello, world!"
-- >
-- >-- Same as:
-- >main =    echo "Hello, world!"

-- $types
--
-- Notice how the above Haskell example used `print` instead of `echo`.  Run the
-- following script to find out what happens if we use `echo` instead of
-- `print`:
--
-- >#!/usr/bin/env runhaskell
-- >
-- >import Turtle
-- >
-- >main = do
-- >    dir  <- pwd
-- >    time <- datefile dir
-- >    echo time
--
-- If we run that we get a type error:
--
-- >$ ./example.hs
-- >
-- >example.hs:8:10:
-- >    Couldn't match expected type `Text' with actual type `UTCTime'
-- >    In the first argument of `echo', namely `time'
-- >    In a stmt of a 'do' block: echo time
-- >    In the expression:
-- >      do { dir <- pwd;
-- >           time <- datefile dir;
-- >           echo time }
--
-- The error occurs on the last line of our program.  If you study the error
-- message closely you'll see that the `echo` function expects a `Text` value,
-- but we passed it @\'time\'@, which was a `UTCTime` value.  Although the error
-- is at the end of our script, Haskell catches this error before even running
-- the script.  When we \"interpret\" a Haskell script the Haskell compiler
-- actually compiles the script without any optimizations to generate a
-- temporary executable and then runs the executable, much like Perl does for
-- Perl scripts.
--
-- You might wonder: \"where are the types?\"  None of the above programs had
-- any type signatures or type annotations, yet the compiler still detected type
-- errors correctly.  This is because Haskell has \"global type inference\",
-- meaning that the compiler can infer the type of any expression within the
-- program without any assistance from the programmer.
--
-- You can even ask the compiler what the type of an expression is using @ghci@.
-- Let's open up the REPL and import this library so that we can study the types
-- and deduce why our program failed:
--
-- >$ ghci
-- >...
-- >Prelude> import Turtle
-- >Prelude Turtle>
--
-- You can interrogate the REPL for an expression's type using the @:type@
-- command:
--
-- >Prelude Turtle> :type echo
-- >echo :: Text -> IO ()
--
-- Whenever you see something of the form @(x :: t)@, that means that @\'x\'@
-- is a value of type @\'t\'@.  The above type says that `echo` is a function
-- whose argument is a value of type `Text` and whose result is a subroutine
-- with an empty return value (denoted @\'()\'@).
--
-- Let's compare that with the type for `pwd`:
--
-- >Prelude Turtle> :type pwd
-- >pwd :: IO Turtle.FilePath
--
-- That says that `pwd` is a subroutine that returns a `Turtle.FilePath`.  The
-- @Turtle@ prefix before `Turtle.FilePath` is just the module qualifier (since
-- the name `Turtle.FilePath` conflicts with the default `FilePath` provided by
-- Haskell's @Prelude@).
--
-- We can similarly ask for the type of `datefile`:
--
-- >Prelude Turtle> :type datefile
-- >datefile :: Turtle.FilePath -> IO UTCTime
--
-- `datefile` is a function whose argument must be a `Turtle.FilePath` and whose
-- result is a subroutine that returns a `UTCTime`.
--
-- `UTCTime` is not the same type as `Text`.  If you try to use either one in
-- place of the other you will get a type error.  This is why our program failed
-- when we tried to `echo` the `UTCTime` returned by `datefile`. The reason
-- `print` works instead of `echo` is because `print` has a more flexible type:
--
-- >Prelude Turtle> :type print
-- >print :: Show a => a -> IO ()
--
-- This type signature says that `print` can display any value of type @\'a\'@
-- so long as @\'a\'@ implements the `Show` interface.  In this case `UTCTime`
-- does implement the `Show` interface, so everything works out when we use
-- `print`.
--
-- This library provides a helper function that lets you convert any type that
-- implements `Show` into a `Text` value:
-- 
-- > -- This behaves like Python's `repr` function
-- > repr :: Show a => a -> Text
--
-- You could therefore implement `print` in terms of `repr`:
--
-- > print txt = echo (repr text)

-- $shell
--
-- You can use @ghci@ for more than just inferring types.  You can use @ghci@ as
-- a general-purpose Haskell shell for your system when you extend it with
-- @turtle@:
--
-- >$ ghci
-- >...
-- >Prelude> :set -XOverloadedStrings
-- >Prelude> import Turtle
-- >Prelude Turtle> cd "/tmp"
-- >...
-- >Prelude Turtle> pwd
-- >FilePath "/tmp"
-- >Prelude Turtle> mkdir "test"
-- >Prelude Turtle> cd "test"
-- >Prelude Turtle> touch "file"
-- >Prelude Turtle> testfile "file"
-- >True
-- >Prelude Turtle> rm "file"
-- >Prelude Turtle> testfile "file"
-- >False
--
-- You can also optionally configure @ghci@ to run the first two commands every
-- time you launch @ghci@.  Just create a @.ghci@ within your current directory
-- with these two lines:
--
-- >:set -XOverloadedStrings
-- >import Turtle
--
-- You can enable those two commands permanently by adding the above file to
-- your home directory.
--
-- @ghci@ accepts two types of commands.  You can provide a subroutine for
-- @ghci@ to run and @ghci@ will execute the subroutine, printing the return
-- value if it is not empty:
--
-- >Prelude Turtle> system "true" empty
-- >ExitSuccess
-- >Prelude Turtle> system "false" empty
-- >ExitFailure 1
--
-- You can also type in a pure expression and @ghci@ will evaluate that
-- expression:
--
-- >Prelude Turtle> 2 + 2
-- >4
-- >Prelude Turtle> "123" <> "456"  -- (<>) concatenates strings
-- >"123456"

-- $signatures
--
-- Haskell performs global type inference, meaning that Haskell never requires
-- any type signatures.  Type signatures in Haskell are entirely for the benefit
-- of programmers and behave like machine-checked documentation.
--
-- Let's illustrate this by adding types to our original script:
--
-- >#!/usr/bin/env runhaskell
-- >
-- >import Turtle
-- >
-- >datePwd :: IO UTCTime  -- Type signature
-- >datePwd = do
-- >    dir <- pwd
-- >    datefile dir
-- >
-- >main :: IO ()          -- Type signature
-- >main = do
-- >    time <- datePwd
-- >    print time
--
-- The first type signature says that @datePwd@ is a subroutine that returns a
-- `UTCTime`:
--
-- >--         +----- A subroutine ...
-- >--         |
-- >--         |  +-- ... that returns `UTCTime`
-- >--         |  |
-- >--         v  v
-- >datePwd :: IO UTCTime
--
-- The second type signature says that @main@ is a subroutine that returns an
-- empty value:
--
-- >--      +----- A subroutine ...
-- >--      |
-- >--      |  +-- ... that returns an empty value (i.e. `()`)
-- >--      |  |
-- >--      v  v
-- >main :: IO ()
--
-- Not every top-level value has to be a subroutine, though.  For example, you
-- can define unadorned `Text` values at the top-level, as we saw previously:
--
-- >#!/usr/bin/env runhaskell
-- >
-- >{-# LANGUAGE OverloadedStrings #-}
-- >
-- >import Turtle
-- >
-- >str :: Text
-- >str = "Hello!"
-- >
-- >main :: IO ()
-- >main = echo str
--
-- These type annotations do not assist the compiler.  Instead, the compiler
-- infers the type independently and then checks whether the inferred type
-- matches the documented type.  If there is a mismatch the compiler will emit a
-- type error.
--
-- Let's test this out by providing an incorrect type for @\'str\'@:
--
-- >#!/usr/bin/env runhaskell
-- >
-- >{-# LANGUAGE OverloadedStrings #-}
-- >
-- >import Turtle
-- >
-- >str :: Int
-- >str = "Hello!"
-- >
-- >main :: IO ()
-- >main = echo str
--
-- If you run that script, you will get two error messages:
--
-- >$ ./example.hs
-- >
-- >example.hs:8:7:
-- >    No instance for (IsString Int)
-- >      arising from the literal `"Hello, world!"'
-- >    Possible fix: add an instance declaration for (IsString Int)
-- >    In the expression: "Hello, world!"
-- >    In an equation for `str': str = "Hello, world!"
-- >
-- >example.hs:11:13:
-- >    Couldn't match expected type `Text' with actual type `Int'
-- >    In the first argument of `echo', namely `str'
-- >    In the expression: echo str
-- >    In an equation for `main': main = echo str
--
-- The first error message is related to the @OverloadedStrings@ extensions.
-- When we enable @OverloadedStrings@ the compiler overloads string literals,
-- interpreting them as any type that implements the `IsString` interface.  The
-- error message says that `Int` does not implement the `IsString` interface so
-- the compiler cannot interpret a string literal as an `Int`.  On the other
-- hand the `Text` and `Turtle.FilePath` types do implement `IsString`, which
-- is why we can interpret string literals as `Text` or `Turtle.FilePath`
-- values.
--
-- The second error message says that `echo` expects a `Text` value, but we
-- declared @str@ to be an `Int`, so the compiler aborts compilation, requiring
-- us to either fix or delete our type signature.
--
-- Notice that there is nothing wrong with the program other than the type
-- signature we added.  If we were to delete the type signature the program
-- would compile and run correctly.  The sole purpose of the type signature in
-- this example is for us to communicate our expectations to the compiler so
-- that the compiler can warn us if the code violate our expectations.
--
-- Let's also try reversing the type error, providing a number where we expect
-- a string:
--
-- >#!/usr/bin/env runhaskell
-- >
-- >{-# LANGUAGE OverloadedStrings #-}
-- >
-- >import Turtle
-- >
-- >str :: Text
-- >str = 4
-- >
-- >main :: IO ()
-- >main = echo str
--
-- This gives a different error:
--
-- >$ ./example.hs
-- >
-- >example.hs:8:7:
-- >    No instance for (Num Text)
-- >      arising from the literal `4'
-- >    Possible fix: add an instance declaration for (Num Text)
-- >    In the expression: 4
-- >    In an equation for `str': str = 4
--
-- Haskell also automatically overloads numeric literals, too.  The compiler
-- interprets integer literals as any type that implements the `Num` interface.
-- The `Text` type does not implement the `Num` interface, so we cannot
-- interpret numeric literals as `Text` strings.

-- $system
--
-- You can invoke arbitrary shell commands using the `system` command.  For
-- example, we can write a program to create an empty directory and then archive
-- the directory:
--
-- >#!/usr/bin/env runhaskell                    -- #!/bin/bash
-- >                                             --
-- >{-# LANGUAGE OverloadedStrings #-}           --
-- >                                             --
-- >import Turtle                                --
-- >                                             --
-- >main = do                                    --
-- >    mktree "test"                            -- mkdir -p test
-- >    system "tar czf test.tar.gz test" empty  -- tar czf test.tar.gz test
--
-- If you run this program, it will generate the @test.tar.gz@ archive:
--
-- >$ ./example.hs
-- >ExitSuccess
-- >$ echo $?
-- >0
-- >$ ls test.tar.gz
-- >test.tar.gz
--
-- Like @ghci@, @runhaskell@ prints any non-empty result of the @main@
-- subroutine (`ExitSuccess` in this case).
--
-- Let's look at the type of `system` to understand how it works:
--
-- >system
-- >    :: Text         -- Shell command to run
-- >    -> Shell Text   -- Standard input (as lines of `Text`)
-- >    -> IO ExitCode  -- Exit code of the shell command
--
-- The first argument is a `Text` representation of the command to run.  The
-- second argument lets you feed input to the command, and you can provide
-- `empty` for now to feed no input.
--
-- The final result is an `ExitCode`, which you can use to detect whether the
-- command completed successfully.  For example, we could print a more
-- descriptive error message if an external command fails:
--
-- >#!/usr/bin/env runhaskell
-- >
-- >{-# LANGUAGE OverloadedStrings #-}
-- >
-- >import Turtle
-- >
-- >main = do
-- >    let cmd = "false"
-- >    x <- system cmd empty
-- >    case x of
-- >        ExitSuccess   -> return ()
-- >        ExitFailure n -> die (cmd <> " failed with exit code: " <> repr n)
--
-- This prints an error message since the @false@ command always fails:
--
-- >$ ./example.hs
-- >example.hs: user error (false failed with exit code: 1)
--
-- Most of the commands in this library do not actually invoke an external
-- shell.  Instead, they indirectly wrap multiple libraries that provide foreign
-- bindings to C code for greater performance and portability.
