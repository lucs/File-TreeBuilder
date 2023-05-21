unit class File::TreeBuilder:ver<0.1.1>:auth<zef:lucs>;

=begin pod

=head1 NAME

    File::TreeBuilder - Build text-scripted trees of files

=head2 SYNOPSIS

=begin code
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
=end code

The example code would create the following directories and files
under the parent directory, which must already exist:

=begin code
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

=end code

=head2 DESCRIPTION

This module exports the C<build-tree> function, used for building and
populating simple trees of files and directories. I have found this
useful to build test data for programs that need such things. Invoke
the function like this:

=begin code
    build-tree(
        IO::Path $parent-dir,
        Str $tree-desc,
        %file-contents?,
    )
=end code

C<$parent-dir> is the directory under which the needed files and
directories will be created. It must already exist and have write
permission.

C<$tree-desc> is a multiline string describing a hierarchy of needed
directories and files and their contents.

The optional C<%file-contents> argument can be used to specify
arbitrary file contents, as will be explained below.

=head3 The tree description

Within the C<$tree-desc> string, blank or empty lines are discarded
and ignored. The string must also not contain any tab characters. The
first non-blank character of each remaining line must be one of:

=begin code
    # : Comment line, will be discarded and ignored.
    / : The line describes a wanted directory.
    . : The line describes a wanted file.
=end code

Any other first non-blank is invalid.

=head4 Directory descriptions

Directory descriptions must mention a directory name. The leading ‹/›
can optionally be immmediately followed by a three-digit octal
representation of the desired permissions of the directory and/or by a
space-representing character to be used if the directory name is to
contain spaces, and must then be followed by whitespace and the
directory name. For example:

=begin code
    / d       : Directory 'd'.
    /X dXc    : Directory 'd c'; spaces in its name are represented by 'X'.
    /600 e    : Directory 'e', permissions 600 (octal always).
    /755_ a_b : Directory 'a b', permissions 755.

    /         : Error: Missing directory name.
    /644      : Error: Missing directory name.
    / abc de  : Error: unexpected data (here, 'de').
=end code

=head4 File descriptions

File descriptions must mention a file name. The leading ‹.› can
optionally be immmediately followed by a three-digit octal
representation of the desired permissions of the file and/or by a
space-representing character to be used if the file name is to contain
spaces, and must then be followed by whitespace and the file name, and
then optionally be followed by whitespace and by a specification of
their wanted contents, as one of either:

=begin code
    . ‹literal contents›
    % ‹key of contents to be retrieved from the %file-contents argument›
=end code

A ‹.› means to place the trimmed rest of the line into the created
file. The program will replace C<\t>, C<\n>, C<\s>, and C<\\> with
actual tabs, newlines, spaces, and backslashes in the file inserted
content. If a line ends with a single ‹\›, the line that follows it
will be concatenated to it, having its leading spaces removed.

A ‹%› means to take the trimmed rest of the line as a key into the
instance's C<%file-contents> and to use the corresponding found value
as the file contents.

For example:

=begin code
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
=end code

=head4 Hierarchy

Directories are created hierarchically, according to the indentation.
Files are created in the directory hierarchically above them. In the
hierarchy then, these are okay:

=begin code
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
=end code

But these are not:

=begin code
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
=end code

=head2 AUTHOR

Luc St-Louis <lucs@pobox.com>

=head2 COPYRIGHT AND LICENSE

Copyright 2023

This library is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=end pod

# --------------------------------------------------------------------
class Node {...}

    # This grammar can be used on the tree description string after
    # having removed blank and comment lines and having concatenated
    # continuation lines.
grammar Node::Grammar {
    token TOP { <LeadWs> [ <Comment> | <Dir> | <File> ] }
    token LeadWs { \s* }
    token Comment { '#' .* }
    token Dir  { '/' <Perms>? <SpRepr>? \s+ <Name> }
    token File { '.' <Perms>? <SpRepr>? \s+ <Name> [\s+ <FData>]? }
    regex FData { [ '.' \s+ <Text> | '%' \s+ <Key> ] }
    token Name { \S+ }
    token Text { .+ }
    token Key { \w+ }
    token Perms { \d\d\d }

        # Never was able to make the ⌊<-space +print>⌉ version work.
   # token SpRepr { <-space +print> }
    token SpRepr { \w }
}

class Node::Actions {
    has Node $.n is rw;

    method TOP ($/) {
        $!n.lead-ws = $<LeadWs>.made;
        make $!n;
    }

    method Comment ($/) {
        $!n.type = '#';
    }

    method Dir ($M) {
        $!n.type = '/';
        $!n.blank = $M<SpRepr>.made;
        $!n.perms = $M<Perms>.made;
        $!n.name = $M<Name>.made;

        if my $b = $!n.blank {
            $!n.name ~~ s:g/$b/ /;
        }
    }

    method File ($M) {
        $!n.type = '.';
        $!n.blank = $M<SpRepr>.made;
        $!n.perms = $M<Perms>.made;
        $!n.name = $M<Name>.made;

        if my $b = $!n.blank {
            $!n.name ~~ s:g/$b/ /;
        }

            # Fix tabs, newlines, and backslashes.
        if my $text = $M<FData><Text>.made {
            $text ~~ s:g,'\\t',\t,;
            $text ~~ s:g,'\\n',\n,;
            $text ~~ s:g,'\\',\\,;
            $!n.text = $text;
        }

        if my $key = $M<FData><Key>.made {
            $!n.key = $key;
        }

    }

    method LeadWs ($/) {
        make $/.chars;
    }

    method Name ($/) {
        make ~$/;
    }

    method Perms ($/) {
            # Keep it as a string; we want octal.
        make ~$/;
    }

    method SpRepr ($/) {
        make ~$/;
    }

    method Text ($/) {
        make ~$/;
    }

    method Key ($/) {
        make ~$/;
    }

}

# --------------------------------------------------------------------
class NodeX is Exception {
    has $.line-text;
    has $.line-num;
    method message { self.WHAT.perl ~ " : L-$.line-num, ‹$.line-text›" }

    method report-here ($line-text, $line-num) {
        return self.bless:
            :$line-text,
            :$line-num,
        ;
    }

}

class NodeX::MalformedLine   is NodeX { }
class NodeX::NoFileDataHash  is NodeX { }
class NodeX::MissingFileData is NodeX { }
class NodeX::InvalidIndent   is NodeX { }

# --------------------------------------------------------------------
class Node {

        # The original line. Examples:
        #   /600 D-1
        #   . F_4 % da_key
        #   .@ F@2 . Explicit contents.\n
    has Str $.line is rw;

        # One of <# / .>.
    has Str $.type is rw = '#';

    has Str $.blank is rw;

        # We expect an octal string.
    has Str $.perms is rw;

        # ⦃Explicit text.\n⦄ or Nil.
    has Str $.text is rw;

        # ⦃da_key⦄ or Nil.
    has Str $.key is rw;

        # Leading whitespace length.
    has Int $.lead-ws is rw;

        # ⦃somefile⦄
    has Str $.name is rw;

        # Hmm...
    has Str $.path is rw;

    method from-text (Str $line-text, $line-num = 1) {
        my Node $node .= new;
        CATCH {
            when NodeX {
                    # Rethrow with correctly populated attributes.
                note $_.new(
                    :$line-text,
                    :$line-num,
                ).throw;
            }
        }
        if $line-text !~~ /^ \s* ['#'|$] / {
            my $parse = (Node::Grammar.new.parse:
                $line-text,
                :actions(Node::Actions.new: :n($node)),
            ) or die NodeX::MalformedLine.new;
        }
        return $node;
    }

}

# --------------------------------------------------------------------
method !build-nodes (
    Str $tree-desc,
    %file-contents?,
) {

        # Shift width levels. Keys are the number of indentation
        # spaces for that level, values, the corresponding level
        # (from 0 on up), ⦃0 => 0, 4 => 1, 8 => 2, ⋯⦄
    my %swid-level;
    %swid-level<-1> = -1;
    my $max-swid = -1;

    my $swid-level-last = -1;
    my $nodetype-last = '/';

        # Split into lines, but keep blank lines and comments so as to
        # keep the count of lines intact for error reporting.
    my @lines = $tree-desc.lines;

    my $line-num = 0;
    my @nodes;
    my @path-stack;
    while ($line-num < @lines) {
        ++$line-num;

        my $node = Node.from-text(@lines[$line-num - 1], $line-num);
        if $node.type eq '#' {
            @nodes.push: $node;
            next;
        }

        my $swid-level-curr;

        my $swid = $node.lead-ws;
        if (%swid-level{$swid}:exists) {
            $swid-level-curr = %swid-level{$swid};
        }
        elsif ($swid < $max-swid) {
            die NodeX::InvalidIndent.report-here: $node.line, $line-num;
        }
        else {
            $swid-level-curr = %swid-level{$max-swid} + 1;
            %swid-level{$swid} = $swid-level-curr;
            $max-swid = $swid;
        }

            # Validate the indentation.
        if ($swid-level-curr > $swid-level-last) {
            if ($swid-level-curr != $swid-level-last + 1) {
                die NodeX::InvalidIndent.report-here: $node.line, $line-num;
            }
            elsif $nodetype-last ne '/' {
                die NodeX::InvalidIndent.report-here: $node.line, $line-num;
            }
        }

        if $node.key {
            if ! %file-contents.defined {
                die NodeX::NoFileDataHash.report-here: $node.line, $line-num;
            }
            if $node.key !~~ %file-contents {
                die NodeX::MissingFileData.report-here: $node.line, $line-num;
            }
        }

            # Save a new node.
        @path-stack[$swid-level-curr] = $node.name;
        $node.path = @path-stack[0..$swid-level-curr].join("/");
        @nodes.push: $node;

            # Get ready for next line.
        $nodetype-last = $node.type;
        $swid-level-last = $swid-level-curr;
    }

    return @nodes;
}

# --------------------------------------------------------------------
our sub build-tree (
    IO::Path $parent-dir,
    $tree-desc,
    %file-contents?,
) is export {

    die "No such directory: '$parent-dir'." unless $parent-dir.d;
    die "Directory '$parent-dir' is not writable." unless $parent-dir.w;

    my Node @nodes = File::TreeBuilder!build-nodes: $tree-desc, %file-contents;

    for @nodes -> $node {
        next if $node.type eq '#';
        my $path = $parent-dir ~ '/' ~ $node.path;
        if $node.type eq '/' {
            mkdir($path) or die "Couldn't create directory '$path'.";
        }
        elsif $node.type eq '.' {
            my $f = open $path, :w or die "Can't write to '$path'.";
            if $node.text {
                $f.print: $node.text;
            }
            elsif $node.key {
                $f.print: %file-contents{$node.key};
            }
            $f.close or die "Couldn't close '$path'.";
        }
        if $node.perms {
                # Make sure we consider the perms as octal.
            my $perms = $node.perms.parse-base: 8;
                # Set the perms as required.
            $path.IO.chmod: $perms;
        }
    }
}

