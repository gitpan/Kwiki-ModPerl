package Kwiki::ModPerl;
use warnings;
use strict;
use Kwiki '-Base';
use Apache::Constants qw(:response :common);

our $VERSION = "0.03";

# create a new kwiki
sub our_kwiki {
    my $path = shift;
    $self->new->debug;
}

# create a new hub and initialize it
sub our_hub {
    my $path = shift;
    chdir $path;
    my $hub = $self->our_kwiki($path)->load_hub(
        "config.yaml", -plugins => "plugins");
    $hub->load_class('config')->script_name('');
    return $hub;
}

sub handler ($$) {
    my ($self, $r) = @_;

    # only handle the directory specified in the apache config.
    # return declined to let Apache serve regular files.
    my $path = $r->dir_config('KwikiBaseDir');
    return DECLINED unless $r->filename eq $path;

    # grab our objects
    my $hub = $self->our_hub($path);
    my $html = $hub->process;

    # now we're just copying most of Kwiki::process()
    if ( defined $html ) {

        # redirect in a mod_perl way.
        # without $r->uri, after edits Kwiki will redirect to URIs like
        # "?HomePage" -- browsers like IE and FireFox handle this just fine,
        # but Safari explodes. We need to prepend the base URI, even if it's
        # just "/" or "/kwiki/" to get "/kwiki/?HomePage".
        if ( ref $html ) {
            $r->headers_out->set(Location=>$r->uri.$html->{redirect});           
            $r->headers_out->set(URI=>$r->uri.$html->{redirect});           
            $r->status(REDIRECT);
            $r->send_http_header;
        }

        # looks like we've got a regular old page.
        else {

            # eventually this calls CGI::header(), which has mod_perl support
            # built into it! yeah, what a lifesaver!
            $hub->load_class('cookie')->header;
            $self->utf8_encode($html);
            print $html;
        }
    }

    # do any modules hook on post_processing?
    $hub->post_process;

    return OK;          
}

1;

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

=item * B<Multiple Kwikis are supported.> As long as each Kwiki has its own
KwikiBaseDir, you're golden.

=item * B<You might need a redirect for the Kwiki base directory.> For example,
if your Kwiki is at the location C</kwiki/> and you browse to C</kwiki>
(without the trailing slash), you'll definitely experience some weirdness.
I highly suggest adding a redirect:

    RedirectMatch ^/kwiki$ http://example.com/kwiki/

=item * B<Yes, viewing F<index.cgi> shows the source of the CGI script.> Don't worry, it's not executing it. It probably similar to the L<index.cgi included with Kwiki|http://search.cpan.org/src/INGY/Kwiki-0.33/lib/Kwiki/Files.pm>, anyway.

=item * B<You might need to restart Apache.> Module additions and removal seem to work.

=back

=head1 AUTHORS

Ian Langworth <langworth.com> 

=head1 SEE ALSO

L<Kwiki>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

