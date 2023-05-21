[![Actions Status](https://github.com/lucs/File-TreeBuilder/actions/workflows/test.yml/badge.svg)](https://github.com/lucs/File-TreeBuilder/actions)

NAME
====

    File::TreeBuilder - Build text-scripted trees of files

SYNOPSIS
--------

        use File::TreeBuilder;

        my $tree-desc = Q:to/EoDesc/;
                # Note that this heredoc string is literal ('Q'), so no
                # interpolation occurs at all. The program will replace
                # the literal '\n', '\t', '\s' (representing a space), and
                # '\\' by the correct characters.

                # Also, empty lines and lines starting with '#'
                # will be discarded and ignored.

                # It is invalid for any real tab characters to appear in
                # this string, so indentation must be accomplished with
                # spaces only. And the indentation must be coherent (bad
                # examples are shown later).

                # What follows is an example of an actual tree of files
                # and directories that one might want to build. It has
                # examples of pretty much all the features the program
                # supports, described in detail later.

            / D1
                . F1

            . F2 . File\n\twith tab, newlines and 2 trailing space.\n\s\s

            /_ D_2
                .x  Fx3
                /600 D3
                    . F4 % f4-key

                .755é Fé5

            . F6 . \sLine continued, \
                and backslash and 't': \\t.
        EoDesc

        my %file-contents = (
            f4-key => "File contents from hash.".uc,
        );

        my $parent-dir = '/home/lucs/File-TreeBuilder.demo'.IO;

        build-tree(
            $parent-dir,
            $tree-desc,
            %file-contents,
        );

The example code would create the following directories and files under the parent directory, which must already exist:

        D1/
            F1
        F2
        D 2/
            F 3
            D3/
                F4
            F 5
        F6

    Note that:

        The 'D1' directory will have default permissions.

        The 'F1' file will be empty and have default permissions.

        The 'F2' file will contain :
        "File\n\twith tab, newlines and 2 trailing spaces.\n  ".

        The 'D 2' directory has a space in its name.

        The 'F 3' file has a space in its name.

        The 'D3' directory will have permissions 0o600.

        The 'F4' file will contain "FILE CONTENTS FROM HASH.".

        The 'F 5' file has a space in its name and will have permissions
        0o755.

        The 'F6' file will contain " Line continued, and backslash and 't': \\t."

DESCRIPTION
-----------

This module exports the `build-tree` function, used for building and populating simple trees of files and directories. I have found this useful to build test data for programs that need such things. Invoke the function like this:

        build-tree(
            IO::Path $parent-dir,
            Str $tree-desc,
            %file-contents?,
        )

`$parent-dir` is the directory under which the needed files and directories will be created. It must already exist and have write permission.

`$tree-desc` is a multiline string describing a hierarchy of needed directories and files and their contents.

The optional `%file-contents` argument can be used to specify arbitrary file contents, as will be explained below.

### The tree description

Within the `$tree-desc` string, blank or empty lines are discarded and ignored. The string must also not contain any tab characters. The first non-blank character of each remaining line must be one of:

        # : Comment line, will be discarded and ignored.
        / : The line describes a wanted directory.
        . : The line describes a wanted file.

Any other first non-blank is invalid.

#### Directory descriptions

Directory descriptions must mention a directory name. The leading ‹/› can optionally be immmediately followed by a three-digit octal representation of the desired permissions of the directory and/or by a space-representing character to be used if the directory name is to contain spaces, and must then be followed by whitespace and the directory name. For example:

        / d       : Directory 'd'.
        /X dXc    : Directory 'd c'; spaces in its name are represented by 'X'.
        /600 e    : Directory 'e', permissions 600 (octal always).
        /755_ a_b : Directory 'a b', permissions 755.

        /         : Error: Missing directory name.
        /644      : Error: Missing directory name.
        / abc de  : Error: unexpected data (here, 'de').

#### File descriptions

File descriptions must mention a file name. The leading ‹.› can optionally be immmediately followed by a three-digit octal representation of the desired permissions of the file and/or by a space-representing character to be used if the file name is to contain spaces, and must then be followed by whitespace and the file name, and then optionally be followed by whitespace and by a specification of their wanted contents, as one of either:

        . ‹literal contents›
        % ‹key of contents to be retrieved from the %file-contents argument›

A ‹.› means to place the trimmed rest of the line into the created file. The program will replace `\t`, `\n`, `\s`, and `\\` with actual tabs, newlines, spaces, and backslashes in the file inserted content. If a line ends with a single ‹\›, the line that follows it will be concatenated to it, having its leading spaces removed.

A ‹%› means to take the trimmed rest of the line as a key into the instance's `%file-contents` and to use the corresponding found value as the file contents.

For example:

        . f         : File "f", contents empty (default), default permissions.
        ._ f_a      : File "f a": spaces in its name are represented by '_'.
        .444Z fZb   : File "f b", permission 444.
        . f . me ow : File "f", literal contents: "me ow".
        . f % k9    : File "f", contents retrieved from %file-contents<k9>.
        . f . This line \
            continues.\n
                    : File "f", contents are "This line continues.\n".

        .           : Error: missing filename.
        . f x       : Error: unrecognized ‹x›.
        . f % baz   : Error if %file-contents wasn't specified
                      or if key ‹baz› is missing from it.
        . f %       : Error: No key specified.

#### Hierarchy

Directories are created hierarchically, according to the indentation. Files are created in the directory hierarchically above them. In the hierarchy then, these are okay:

            Directories and files intermixed on the same level.
        / d1
        / d2
        . f1
        . f2
        / d3

            A directory holding a subdirectory or a file.
        / d1
            / d2
                . f1

            Returning to a previously established level, here at ‹. f2›.
        / d1
            / d2
                / d3
                    . f1
            . f2

But these are not:

            A file cannot hold a file.
        . f1
            . f2

            Nor can it hold a directory.
        . f1
            / d1

            ‹/ d3›'s indentation conflicts with those of ‹/ d1› and ‹/ d2›.
        / d1
            / d2
          / d3

            ‹/ d5›'s indentation conflicts with those of ‹/ d2› and ‹/ d3›.
        / d1
            / d2
                / d3
        / d4
              / d5

AUTHOR
------

Luc St-Louis <lucs@pobox.com>

COPYRIGHT AND LICENSE
---------------------

Copyright 2023

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

