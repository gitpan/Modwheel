#!/usr/bin/perl
use strict;
use warnings;
use Modwheel::Session;
use BerkeleyDB;

my $modwheel_config = {
    prefix      => '/opt/modwheel',
    configfile  => 'config/modwheelconfig.yml',
};

my ($modwheel, $user, $db, $object, $repository, $template)
    = modwheel_session($modwheel_config);

my $c = Changes->new({
    modwheel    => $modwheel,
    db          => $db,
    object      => $object,
    repository  => $repository,
    template    => $template,
});

package Changes;
use Class::InsideOut::Policy::Modwheel qw(:std);
use base 'Modwheel::Instance';
{

    public changes_db   => my %changes_db_for,  {is => 'rw'};
    public file         => my %file_for,        {is => 'rw'};

    sub new {
        my $class   = shift;
        my $self    = $class->SUPER::new(@_);
        my $arg_ref = shift;
        

        my $modwheel  = $self->modwheel;
        my $db_file   = $modwheel->siteconfig->{Changes}{DatabaseFile};
           $db_file ||= $arg_ref->{file};
        $file_for{ident $self} = $db_file;

        my $env = BerkeleyDB::Env->new(
            -Home => $modwheel->prefix,
        );

        my $db = BerkeleyDB::Hash->new(
            -Filename => $db_file,
            -Env      => $env,
        );

        $changes_db_for{ident $self} = $db_file;

        return $self;
}




}
