package Kwiki::ModPerl;
use Kwiki -Base;
use Apache::Constants qw(:response :common);

our $VERSION = "0.05";

sub get_new_hub {
    my $path = shift;
    chdir $path;
    my $hub = $self->new->debug->load_hub(
        "config.yaml", -plugins => "plugins",
    );
    return $hub;
}

sub handler : method {
    my ($self, $r) = @_;

    # only handle the directory specified in the apache config.
    # return declined to let Apache serve regular files.
    my $path = $r->dir_config('KwikiBaseDir');
    # modperl 2 gives trailing slash
    my $rpath = $r->filename;
    $rpath =~ s/(\/index.cgi)?\/?$//;

    # Support sub-view. sub_view = sub-dir with the "registry.dd" file.
    $path = $rpath if(io->catfile($rpath,"registry.dd")->exists);

    return DECLINED unless $rpath eq $path;
    my $hub = $self->get_new_hub($path);

    my $html = eval {
        $hub->pre_process;
        $hub->process;
    };
    return $self->print_error($@,$r,$hub) if $@;

    if (defined $html) {
        $hub->headers->print;
        unless($r->header_only) {
            $self->utf8_encode($html);
            $r->print($html);
        }
    }
    $hub->post_process;
    return ($hub->headers->redirect)?REDIRECT:OK;
}

sub print_error {
    my $error = $self->html_escape(shift);
    my $r = shift;
    my $hub = shift;
    $hub->headers->content_type('text/html');
    $hub->headers->charset('UTF-8');
    $hub->headers->expires('now');
    $hub->headers->pragma('no-cache');
    $hub->headers->cache_control('no-cache');
    $hub->headers->redirect('');
    $hub->headers->print;
    $r->print("<h1>Software Error:</h1><pre>\n$error</pre>");
    return OK;
}

__DATA__

=head1 NAME

Kwiki::ModPerl - enable Kwiki to work under mod_perl

=head1 SYNOPSIS

 $ kwiki -new /path/to/webroot/kwiki

In your Apache configuration:

 <Location /kwiki>
   SetHandler  perl-script
   PerlSetVar  KwikiBaseDir /path/to/webroot/kwiki
   PerlHandler +Kwiki::ModPerl
 </Location>

If you have a custom F<lib> directory for your Kwiki:

 <Perl>
   use lib '/path/to/webroot/kwiki/lib';
 </Perl>

=head1 DESCRIPTION

This module allows you to use Kwiki as a mod_perl content handler.

=head1 FEATURES, BUGS and NOTES

=over 4

=item * B<Sub-view are supported automatically>

No extra apache configuration is required.

=item * B<Multiple Kwikis are supported.>

As long as each Kwiki has its own KwikiBaseDir, you're golden.

=item * B<You might need a redirect for the Kwiki base directory.>

For example, if your Kwiki is at the location C</kwiki/> and you
browse to C</kwiki> (without the trailing slash), you'll definitely
experience some weirdness.  I highly suggest adding a redirect:

    RedirectMatch ^/kwiki$ http://example.com/kwiki/

=item * B<Why index.cgi still shows up in the URL ?>

Don't worry, it's ignored internally, so that it is still handled
under mod_perl, not as a cgi script. Also, It can make all browser
happy with relative URI redirection. (Although it shouldn't be a
relative redirection, should be fixed in Kwiki base in the future).

=item * B<You might need to restart Apache.>

Otherwise module additions and removal might not be working.

=back

=head1 AUTHORS

Ian Langworth <langworth.com>

Now Maintained by Kang-min Liu <gugod@gugod.org>

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth
Copyright (C) 2005 by Kang-min Liu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

