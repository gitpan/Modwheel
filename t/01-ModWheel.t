# TESTS FOR Modwheel.pm
use Test::More tests => 114;

BEGIN {
    use lib '/opt/devel/Modwheel/lib';
    use lib './t';
    use_ok('Modwheel');
};

#########################

use Test::Modwheel  qw( :boolean );
use strict;
use warnings;
use Readonly;
use English         qw( -no_match_vars );

#########################


our $THIS_BLOCK_HAS_TESTS;

our $TMP_NULL = './t/cache/.devnull';


Readonly my $TEST_PREFIX     => './';
Readonly my $TEST_CONFIGFILE => 't/modwheelconfig.yml';
Readonly my $TEST_SITE       => 'modwheeltest';
Readonly my $TEST_LOCALE     => 'en_EN';
Readonly my $TEST_LOGMODE    => 'off';

Readonly my @modwheel_prototype => qw(
    debug       set_debug
    prefix      set_prefix
    logmode     set_logmode
    configfile  set_configfile
    site        set_site
    error       set_error
    locale      set_locale
    config      set_config
    logobject   set_logobject
    loghandlers set_loghandlers
    exceptions  set_exceptions
    new
    _setlocale
    locale_setup_with_locale
    locale_setup_from_config
    siteconfig
    parseconfig
    dumpconfig
    install_loghandler
    remove_loghandler
    logerror
    logwarn
    loginform
    _log
    throw
    exception
    catch
    catch_like
);
    
my $modwheel_config = {
    prefix               => $TEST_PREFIX,
    configfile           => $TEST_CONFIGFILE,
    site                 => $TEST_SITE,
    locale               => $TEST_LOCALE,
    logmode              => $TEST_LOGMODE,
    debug                => 1,
};
    

$THIS_BLOCK_HAS_TESTS = 31;
SKIP:
{
    ok( my $modwheel = Modwheel->new($modwheel_config),
        'Create Modwheel root object instance'
    );
    
    # Test if the Modwheel interface confirms to @modwheel_prototype.
    for my $method (@modwheel_prototype) {
        ok( $modwheel->can($method),
            "Test Interface: Modwheel->can: $method()"
        );
    }

    # Test that our arguments was stored properly in the object.
    is( $modwheel->prefix,     $TEST_PREFIX     );
    is( $modwheel->configfile, $TEST_CONFIGFILE );
    is( $modwheel->site,       $TEST_SITE       );
    is( $modwheel->locale,     $TEST_LOCALE     );
    is( $modwheel->logmode,    $TEST_LOGMODE    );

    # Check that no exceptions have already happened at start.
    ok(! $modwheel->exception,  'No exception at start (exception)');
    ok(! $modwheel->catch,      'No exception at start (catch)');
    ok(! $modwheel->catch_like, 'No exception at start (catch_like)');

    ok(! $modwheel->catch('test-this-exception-does-not-exist'), 'catch
non-existing exception' );
    ok(! $modwheel->catch_like('test-this-exception-does-not-exist', 'catch
non-existing exception') );


    my $modwheel_tmp;
    # Test if logmode can be specified as argument.
    $modwheel_config->{logmode} = 'stderr';
    $modwheel_tmp = Modwheel->new($modwheel_config);
    is( $modwheel_tmp->logmode,   'stderr',
        'Logmode can be specified as argument.' 
    );
    $modwheel_config->{logmode} = $TEST_LOGMODE;

    ok( $Modwheel::VERSION,       'We have \$Modwheel::VERSION'  );
    ok( $modwheel->configfile,    'We have a configuration file.');
    ok(ref $modwheel->siteconfig, 'Siteconfig is set up.'        );
    ok($modwheel->locale,         'We have locale.'              );

    $modwheel->locale_setup_with_locale(undef);
    $modwheel->locale_setup_from_config();
    ok( $modwheel->locale,
        'Modwheel::locale_setup_from_config()'
    );

    # Create and test a loghandler.
    our ($global_log_msg, $global_log_facility);
    my $log_messages_to_log_temp = sub {
        my ($modwheel, $log_frmt_msg, $facility, @raw) = @_;
        $global_log_msg      = join q{ }, @raw;
        $global_log_facility = $facility;
        return;
    };

    # install loghandler via method
    ok( $modwheel->install_loghandler('tlg', $log_messages_to_log_temp),
        'Install new log handler with ->install_loghandler()'
    );


    $modwheel->set_logmode('tlg');
    is( $modwheel->logmode, 'tlg',
        'Set log handler to the log handler we installed'
    );

    $modwheel->logerror(  'This is a log of facility Error' );
    is( $global_log_msg,  'This is a log of facility Error', 'logerror()' );
    is( $global_log_facility, 'Error', 'logerror() facility' );

    $modwheel->loginform( 'This is a log of facility Info'  );
    is( $global_log_msg,  'This is a log of facility Info',  'loginform()'  );
    is( $global_log_facility, 'Info', 'loginform() facility'  );
    
    $modwheel->logwarn(   'This is a log of facility Warning' );
    is( $global_log_msg,  'This is a log of facility Warning', 'logwarn()' );
    is( $global_log_facility, 'Warning', 'logwarn() facility' );

    # ### install loghandler as argument to new

    # reset temp logging vars.
    $global_log_msg = q{};
    $global_log_facility = q{};
    
    my $log_messages_to_log_temp_and_object = sub {
        my ($modwheel, $log_frmt_msg, $facility, @raw) = @_;
        my $logobject = $modwheel->logobject;
        $global_log_msg      = join q{ }, @raw;
        $global_log_facility = $facility;
        $logobject->set_log($global_log_msg);
        return;
    };
    my %mwXX_conf = %{ $modwheel_config };
    $mwXX_conf{add_loghandlers} = {
        'tlgarg' => $log_messages_to_log_temp_and_object,
    };
    my $logobject = TestLogObject->new();
    $mwXX_conf{logmode}   = 'tlgarg';
    $mwXX_conf{logobject} = $logobject;
    my $mwXX = Modwheel->new(\%mwXX_conf);
    
    $mwXX->logerror(  'This is a log of facility Error' );
    is( $global_log_msg,  'This is a log of facility Error', 'logerror()' );
    is( $logobject->log, $global_log_msg, 'log object works');
    is( $global_log_facility, 'Error', 'logerror() facility' );

    $mwXX->loginform( 'This is a log of facility Info'  );
    is( $global_log_msg,  'This is a log of facility Info',  'loginform()'  );
    is( $logobject->log, $global_log_msg, 'log object works');
    is( $global_log_facility, 'Info', 'loginform() facility'  );
    
    $mwXX->logwarn(   'This is a log of facility Warning' );
    is( $global_log_msg,  'This is a log of facility Warning', 'logwarn()' );
    is( $logobject->log, $global_log_msg, 'log object works');
    is( $global_log_facility, 'Warning', 'logwarn() facility' );

    # ### Exceptions

    $modwheel->throw('test-throw-exception');
    ok(! $modwheel->catch('noitpecxe-worht-tset') , 'Catch nonexisting
exception');
    ok(! $modwheel->catch_like('noitpecxe-worht-tset', 'Catch nonexisting
exception') );
    is( $modwheel->exception, 'test-throw-exception', 'exception()');
    ok(!$modwheel->catch('test-throw-exception'), 'exception() pop');
    $modwheel->throw('test-throw-exception');
    ok($modwheel->catch('test-throw-exception'), 'catch()');
    $modwheel->throw('xyxz-smoke-exception');
    ok($modwheel->catch_like('xyxz-smoke'), 'catch_like()');
    $modwheel->throw('zzzz-modmo-exception');
    ok($modwheel->catch, 'catch any exception');
    ok($modwheel->catch_like, 'catch any exception (catch_like');
   

    $modwheel->set_logmode($TEST_LOGMODE);
    ok( $modwheel->remove_loghandler('tlg') );
    
    ok( $modwheel->install_loghandler('0', sub { } ),
        'Install: Loghandler named 0' );
    ok( $modwheel->remove_loghandler('0'),
        'Remove:  Loghandler named 0' );

    my $loghandlers = $modwheel->loghandlers;
    ok(!exists $loghandlers->{tlg});
   
    is($modwheel->debug, 1,
        'We set debug to be on in the test config. Is it still on?'
    );
    is( $modwheel->siteconfig->{uniqueidfortest}, 'SITEID0001' );
    my $dumped_config = $modwheel->dumpconfig;
    ok( $dumped_config, 'Modwheel::dumpconfig' );
    ok( YAML::Syck::Load($dumped_config),
        'YAML::Syck::Load can parse our dumped config'
    );

    ok( my $mw2 = Modwheel->new({
        prefix             => $TEST_PREFIX,
        configfile         => $TEST_CONFIGFILE,
        site               => 'modwheeltest2',
        logmode            => '',
    }), 'Create another Modwheel root object instance, without locale. is this ok?');

    #my $pwd = $ENV{PWD};
    #ok( my $mwX = Modwheel->new({
    #    prefix             => $TEST_PREFIX,
    #    configfile         => "/$pwd/t/config_wo_global_locale.yml",
    #    site               => 'modwheeltest2',
    #    logmode            => '',
    #}), 'Create another Modwheel object without any locale in either args or
#config.');
    is( $mw2->siteconfig->{uniqueidfortest}, 'SITEID0002' );
    ok( my $mwA = Modwheel->new({
        prefix             => "$TEST_PREFIX/t",
    }), 'Create another Modwheel root object instance, without configfile specified.');
    ok( my $mw4 = Modwheel->new({
        prefix             => $TEST_PREFIX,
        configfile         => $TEST_CONFIGFILE,
    }), 'Create another Modwheel root object instance, without site specified.');
    my $defaultsite = $modwheel->config->{global}{defaultsite};
    is( $mw4->site, $defaultsite, '   - site should be set to defaultsite in config.');
    ok( $mw4->siteconfig );
    is( $mw4->locale, 'en_EN' );
    undef $mw2;
    undef $mw4;
    ok(! $modwheel->logerror("Test of logerror()."),
        'Testing Modwheel::log and friends...'
    );
    ok($modwheel->error, '$modwheel->error should be set after logerror() (debug on)' );
    ok(! $modwheel->logwarn(  "Test of logwarn()."  ) );
    ok(! $modwheel->loginform("Test of loginform().") );

    # log without debug
    $modwheel->set_debug(0);
    ok(! $modwheel->logerror("Test of logerror()."));
    ok($modwheel->error, '$modwheel->error should be set after logerror() (debug off)' );
    ok(! $modwheel->logwarn(  "Test of logwarn()."  ) );
    ok(! $modwheel->loginform("Test of loginform().") );

    
    # Warning on empty log message
    $modwheel->logerror( q{} );
    ok($modwheel->error(), 'Warning on empty log message' ); 

 
    eval { 
    open TMPNULL, ">$TMP_NULL"
        or die "Couldn't open $TMP_NULL for writing: $OS_ERROR";
    *STDERR = *TMPNULL;
    $modwheel->set_logmode('xyxzxyxzxyxzxyxzTEST0001');
    $modwheel->logerror('Testing logging without working logmode');
    unlink $TMP_NULL or die "Couldnt unlink $TMP_NULL";
    };
    ok( $modwheel->error, 'Testing logging without working logmode');

}

$THIS_BLOCK_HAS_TESTS=6;
SKIP:
{
    eval 'use Test::Exception';
    skip 'Skipping tests that requires Test::Exception', 1 if $EVAL_ERROR;

    my $modwheel = Modwheel->new($modwheel_config);
    # Loghandler must be CODELIKE
    dies_ok( sub { $modwheel->install_loghandler('abladabla', 1) },
        'Loghandler must be CODELIKE'
    );

    dies_ok( sub { $modwheel->install_loghandler() },
        'Die: Install loghandler with no name'
    );
    dies_ok( sub { $modwheel->remove_loghandler() },
        'Die: Remove loghandler with no name'
    );

    # Test with a bogus configuration file.
    my $modwheel_tmp;
    my %config_tmp = %{ $modwheel_config };
    $config_tmp{configfile} =
        'xyxz/asdsdz/sdsadsa.yml43141321312321/adad8123';
    dies_ok( sub { $modwheel_tmp = Modwheel->new(\%config_tmp) },
    'Should die without config');

    # Bail on missing site.
    %config_tmp = %{ $modwheel_config };
    $config_tmp{site} = 'ABCDEFGHIJKLZZZZZxxxxxxx12&(&(&(';
    dies_ok( sub { $modwheel_tmp = Modwheel->new(\%config_tmp) },
        'Bail on new without explicit Site.'
    );

    %config_tmp = %{ $modwheel_config };
    $config_tmp{prefix} = q{};
    dies_ok( sub { $modwheel_tmp = Modwheel->new(\%config_tmp) },
        'Bail on missing prefix.',
    );

    %config_tmp = %{ $modwheel_config };
    $config_tmp{configfile} = 't/broken_yaml_file.yml';
    dies_ok( sub { $modwheel_tmp = Modwheel->new(\%config_tmp) },
        'Bail on broken config.',
    );
}

package TestLogObject;

sub new {
    return bless { }, shift
}

sub set_log {
    $_[0]->{_log} = $_[1];
    return;
}

sub log {
    return $_[0]->{_log};
}
