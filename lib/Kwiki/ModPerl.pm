package Kwiki::ModPerl;
use Kwiki -Base;
use Apache::Constants qw(:response :common);

our $VERSION = "0.04";

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
    my $rpath = $r->filename;
    # modperl 2 gives trailing slash
    $rpath =~ s{/$}{};
    return DECLINED unless $rpath eq $path;
    my $hub = $self->get_new_hub($path);

    # This would generate an absolute redirection URI
    # that makes all browser (especially Safari) happy
    $hub->config->script_name($r->uri);

    my $html = eval {
        $hub->pre_process;
        $hub->process;
    };
    return $self->print_error($@) if $@;

    if (defined $html) {
        $hub->headers->print;
        $self->utf8_encode($html);
        Apache->request->print($html);
    }

    $hub->post_process;

    return OK;
}

sub print_error {
    my $error = $self->html_escape(shift);
    require CGI;
    print CGI::header();
    print "<h1>Software Error:</h1><pre>\n$error</pre>";
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

=item * B<Multiple Kwikis are supported.>

As long as each Kwiki has its own KwikiBaseDir, you're golden.

=item * B<You might need a redirect for the Kwiki base directory.>

For example, if your Kwiki is at the location C</kwiki/> and you
browse to C</kwiki> (without the trailing slash), you'll definitely
experience some weirdness.  I highly suggest adding a redirect:

    RedirectMatch ^/kwiki$ http://example.com/kwiki/


=item * B<Yes, viewing F<index.cgi> shows the source of the CGI script.>

Don't worry, it's not executing it. It probably similar to the
L<index.cgi included with Kwiki|http://search.cpan.org/src/INGY/Kwiki-0.33/lib/Kwiki/Files.pm>,
anyway.

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

