# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
package FCGI::Modwheel;
use strict;
use warnings;
use 5.00800;
use CGI;
use Modwheel::Session 0.002003;
use Time::HiRes qw(gettimeofday);
use Perl6::Slurp qw(slurp);
use Readonly;
use version; our $VERSION = qv('0.3.2');
use Class::InsideOut::Policy::Modwheel qw(:std);
{
    Readonly my $PREFIX => '/opt/modwheel';
    Readonly my $CONFIG => 'config/modwheelconfig.yml';
    Readonly my $SITE   => 'Admin';

    public cgi        => my %cgi_for,        {is => 'rw'};
    public modwheel   => my %modwheel_for,   {is => 'rw'};
    public db         => my %db_for,         {is => 'rw'};
    public user       => my %user_for,       {is => 'rw'};
    public object     => my %object_for,     {is => 'rw'};
    public repository => my %repository_for, {is => 'rw'};
    public template   => my %template_for,   {is => 'rw'};

    sub new {
        my ($class, $options_ref) = @_;
        my $self = register($class);
        $options_ref ||= {};

        my $cgi = CGI->new( );

        my $modwheel_config = {
            prefix      => $PREFIX,
            configfile  => $CONFIG,
            site        => $SITE,
        };

        my ($modwheel, $user, $db, $object, $repository, $template)
            = modwheel_session($modwheel_config);

        $cgi_for{ident $self}        = $cgi;
        $modwheel_for{ident $self}   = $modwheel;
        $db_for{ident $self}         = $db;
        $user_for{ident $self}       = $user;
        $object_for{ident $self}     = $object;
        $repository_for{ident $self} = $repository;
        $template_for{ident $self}   = $template;

        return $self;

    }

    sub handle_request {
        my ($self, $req, $env)     = @_;
        %ENV = %{ $env };
        my $r          = CGI->new;
        $self->set_cgi($r);
        my $modwheel   = $self->modwheel;
        my $db         = $self->db;
        my $user       = $self->user;
        my $object     = $self->object;
        my $repository = $self->repository;
        my $template   = $self->template;

        my ($start_s, $start_ms) = gettimeofday;

        $db->connect_cached( );

        my ($parent, $page) = $self->get_parent_and_page($req);
        my $o = $object->fetch({id => $parent});
        return $self->simple_print_error("No object with id $parent")
            if !$o;
        if ($o->template) {
            $page = $o->template;
        }
        my $relpage = $page;

        # remove leading slash
        $page =~ s{^/}{}xms;

        $page = join q{/}, $modwheel->siteconfig->{templatedir}, $page;
        return $self->simple_print_error("Page: $relpage, not found")
            if !-f $page;

        my $ret = $template->init(
            {   input  => $page,
                param  => $r,
                parent => $parent,
            }
        );
        return $self->simple_print_error("Template error: $template->errstr")
            if !$ret;

        my ($end_s, $end_ms) = gettimeofday;
        my $compile_s        = $end_s  - $start_s;
        my $compile_ms       = $end_ms - $start_ms;
        my $stash            = $template->stash;
        $stash->set('compile_s',  $compile_s );
        $stash->set('compile_ms', $compile_ms);

        print $r->header('text/html');

        print describe($r->param('parent'), 'parent is set to this in param');
        print describe($r->url(-full => 1), 'full url');
        print describe($r->url(-path_info => 1), 'path info');

        use Data::Dumper;
        print '<pre>';
        print Data::Dumper::Dumper([$env]);
        print '</pre>';

        print $template->process({});

        return 0;
    }

    sub describe {
        my ($text, $description) = @_;
        my $out  = '<h1>' . $text .        '</h1>';
           $out .= '<h2>' . $description . '</h2>';
        return $out;
    }

    sub get_parent_and_page {
        my ($self, $req) = @_;
        my $r         = $self->cgi;
        my $object    = $self->object;
        my $modwheel  = $self->modwheel;
        my $parent    = $r->param('parent');
        my $page      = $r->param('page');
        #my $base_url  = $r->url(-full      => 1);
        #my $path_info = $r->url(-path_info => 1);
        #my $page      = substr $path_info, length $base_url,
        #length $path_info;
#
#        if (!$parent) {
#            $parent = $object->path_to_id($page, '/');
#            return if !$parent;
#        }
#        $page =~ s{ ^.*/ }{}xms;
#        if ($page !~ m/ \.[\w\d_]+$ /xms) {
#            undef $page;
#        }
        $page   ||= $modwheel->siteconfig->{directoryindex};
        $parent ||= Modwheel::Object::MW_TREE_ROOT;

        return ($parent, $page);
    }

    sub simple_print_error {
        my ($self, $errormsg)  = @_;
        my $r           = $self->cgi;
        my $CSS         = slurp \*DATA;
        my $referer     = $r->referer;
        my $server_name = $r->virtual_host;
        $server_name  ||= $r->server_name;
        my $server_port = $r->virtual_port;
        $server_port  ||= $r->server_port;
        my $software    = $r->server_software;

        print <<"HTML"
<html>
    <head>
        <title>Modwheel - Error</title>
        <style type="text/css">
        $CSS
        </style>
    </head>
    <body>
        <h1>There was an error with the page you wanted.</h1>
        <h2>$errormsg</h2>
        <p>
        <a href="$referer"> Go back. </a>
        </p>
        <hr>
        <p>
        <b>Using Modwheel $Modwheel::VERSION</b> &copy; 2007 <a
        href="http://www.0x61736b.net/Modwheel">0x61736b.net</a>- All rights reserved.
        <br />Server: ${server_name}:${server_port}, running $software.</p>
    </body>
    </html>
HTML
            ;
        return 1;
    }

}

1;

__DATA__
body {
    font-size: 12pt;
    font-family: Tahoma, Helvetica, sans-serif;
}
h2 {
    font-weight: bold;
    font-size: 14pt;
    color: #3c3c3c;
    letter-spacing: 0.1em;
}
a:hover {
    background: #ff1032;
    padding: 1px;
    line-height: 100%;
    color: #000;
    font-weight: normal;
}
a {
    padding: 1px;
    font-weight: normal;
    color: #101110;
}
a:link, a:visited {
    padding: 1px;
    line-height: 100%;
    color: #a13c6d;
    font-weight: normal;
}

