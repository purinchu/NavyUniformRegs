#!/usr/bin/env perl

# This file preprocesses the ugly MS HTML generated for the files that
# make up the NPC uniform regulations, stripping out a bunch of the header
# cruft, random JS, ginormous-but-useless tags, and the like.
#
# Depends on the Mojolicious framework (which has good handling of HTML
# thanks to its nature as a Web framework).

use v5.18;
use Mojo::File;
use Mojo::DOM;

my $file = $ARGV[0] // './default.aspx.html';
my $out_file = $ARGV[1] // ($file =~ s,^\./,../compiled-regs/,r);

my $file_content = Mojo::File->new($file)->slurp
    or die "$file";

my $out = Mojo::File->new($out_file)->to_abs;
$out->dirname->make_path;

my $file_dom = Mojo::DOM->new($file_content);

# Half of the script is this line right here, picking out the HTML that is
# contained in the "pageContent" div.  But separately we also need the page
# title from the <head>, otherwise we wouldn't bother retaining file_dom.
my $content_dom = $file_dom->at("div.pageContent")
    or do {
        say "No page content in $file";
        exit 0; # Should this be an error exit instead?  Doing this seems to
                # cause xargs to abort early in that case.
    };
my $title = $file_dom->at('title')->text // 'No title';
$title =~ s/^\s+//; # Remove leading/trailing whitespace
$title =~ s/\s+$//;

# Force unselected parts of DOM to be deleted, otherwise we seem to get
# extraneous cruft from HTML leaking into output.
undef $file_dom;

# Remove some 'Page Content' nodes outright (i.e. things with a display:none
# style, since we're about to remove all style tags)
my $xfrmed_dom = applySelectorTransform($content_dom, 'div[style="display:none"]', sub {
        $_->remove;
    });

# Go through all nodes (returned as a Mojo::Collection), remove any stupid
# built-in "style" attributes.  This changes the DOM tree, but we can obtain
# the new root from any of the elements in the resulting list of DOM nodes.
$xfrmed_dom  = $xfrmed_dom->descendant_nodes->map(sub {
        delete $_->attr->{style}; $_;
    })->first->root;

# removeSelectorAttrValue retains the HTML class attr but removes the specified
# value, if present
$xfrmed_dom = removeSelectorAttrValue($xfrmed_dom, '.MsoNormal', 'class', 'MsoNormal');

# Remove ugly font decls
$xfrmed_dom = removeSelectorAttr($xfrmed_dom, 'font[face]', 'face');
$xfrmed_dom = removeSelectorAttr($xfrmed_dom, 'font[color]', 'color');
$xfrmed_dom = removeSelectorAttr($xfrmed_dom, 'font[size]', 'size');

# Remove ugly div labels and ids
$xfrmed_dom = removeSelectorAttr($xfrmed_dom, 'div[id*="__ControlWrapper_"][id^="ctl00"]', 'id');
$xfrmed_dom = removeSelectorAttr($xfrmed_dom, 'div[aria-labelledby]', 'aria-labelledby');

# Remove ugly table settings.
# TODO: This didn't seem to always work for me when I was investigating with
# Firefox
$xfrmed_dom = removeSelectorAttr($xfrmed_dom, 'td[valign]', 'valign');
$xfrmed_dom = removeSelectorAttr($xfrmed_dom, 'table[cellspacing]', 'cellspacing');
$xfrmed_dom = removeSelectorAttr($xfrmed_dom, 'table[cellpadding]', 'cellpadding');

# Let mobile browser handle width/height by, you guessed it, removing such
# attributes outright.
$xfrmed_dom = removeSelectorAttr($xfrmed_dom, '*[width]', 'width');
$xfrmed_dom = removeSelectorAttr($xfrmed_dom, '*[height]', 'height');

# Remove empty elements (including now-empty <font></font>)
# This doesn't seem to work all the time though (e.g. if there is a stray
# space buried in there).
$xfrmed_dom = applySelectorTransform($xfrmed_dom, ':empty', sub {
        # Don't apply to <img> or <br> since they're inherently empty.
        # This doesn't have a fancy CSS selector syntax so we just check
        # manually
        ($_->tag eq 'img' || $_->tag eq 'br')
            ? $_
            : $_->strip;
    });

# Remove some nodes but keep their content.  We limit to some specific tags
# that also have no HTML attributes.
$xfrmed_dom = applySelectorTransform($xfrmed_dom, 'span, font', sub {
        # Again, no CSS syntax for nodes with *no* attr, so manually check
        # The sub *must* return something so we return the orig node if we
        # don't call ->strip
        (scalar %{$_->attr})
            ? $_
            : $_->strip;
    });

# Remove blockquote even if attr present.  This at least horribly infects
# the index page (Pages/default.aspx) and doesn't seem to be needed elsewhere
$xfrmed_dom = applySelectorTransform($xfrmed_dom, 'blockquote', sub {
        $_->strip
    });

#
# In theory, the DOM has been cleansed by this point.  But we need to package
# it up in a standard HTML shell.
#

# wrap_content places *inside* the first tag encountered with a closing tag
# (i.e. div)
my $wrapped_dom = $xfrmed_dom
    ->wrap_content("<html lang='en'>\n<body><div></div></body>\n</html>")
    ->at('body')  # select the <body> node
    ->prepend("<head><meta charset='utf-8'>\n\t<title>$title</title>\n".
        "<link rel='icon' href='data:;base64,='></head>") # quench favicon requests
    ->root
    ;

# spurt already throws errors on failure, verified in source
$out->spurt($wrapped_dom->content);

# FIN
exit 0;

sub applySelectorTransform
{
    my ($dom, $cssSelector, $fn) = @_;

    my $xfrmed_dom = $dom->find($cssSelector)->map($fn);

    # CSS selectors may not match at all, in that case do nothing
    return $xfrmed_dom->first->root if $xfrmed_dom->first;
    return $dom;
}

sub removeSelectorAttrValue
{
    my ($dom, $cssSelector, $attr, $val) = @_;
    return applySelectorTransform($dom, $cssSelector, sub {
        my $newAttr = $_->attr($attr) =~ s/$val//r;
        if ($newAttr =~ m/^\s*$/) {
            delete $_->attr->{$attr};
        }
        else {
            $_->attr($attr, $newAttr);
        }
        $_;
    });
}

sub removeSelectorAttr
{
    my ($dom, $cssSelector, $attr) = @_;
    return applySelectorTransform($dom, $cssSelector, sub {
        delete $_->attr->{$attr} if $_->attr->{$attr};
        $_;
    });
}
