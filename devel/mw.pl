#!/usr/bin/perl
use strict;
use warnings;
use 5.00800;
use CGI;
use Modwheel::Session 0.002003;
use Readonly;
use version; our $VERSION = qv('0.3.1');

Readonly my $PREFIX => '/opt/modwheel';
Readonly my $CONFIG => 'config/modwheelconfig.yml';
Readonly my $SITE   => 'Admin';

my $r = CGI->new( );

my $modwheel_config = {
    prefix      => $PREFIX,
    configfile  => $CONFIG,
    site        => $SITE,
};

my ($modwheel, $user, $db, $object, $repository, $template)
    = modwheel_session($modwheel_config);

$db->connect( );
my $ret = handle_request($r);
$db->disconnect( );
exit $ret;
sub handle_request {
    my ($r) = @_;

    my ($parent, $page) = get_parent_and_page( );
    my $o = $object->fetch({id => $parent});
    if ($o->template) {
        $page = $o->template;
    }
    $page ||= $modwheel->siteconfig->{directoryindex};

    # remove leading slash
    $page =~ s{^/}{}xms;

    $page = join q{/}, $modwheel->siteconfig->{templatedir}, $page;
    return simple_print_error("Page: $page, not found")
        if !-f $page;

    my $ret = $template->init({
        input  => $page,
        param  => $r,
        parent => $parent,
    });
    return simple_print_error("Template error: $template->errstr")
        if !$ret;

    print $r->header('text/html');
    print '<h1>', $r->url(-relative => 1), '</h1>';
    print $template->process({ });

    return 0;
}

sub get_parent_and_page {
    return (1, 'index.html');
}
     
    
