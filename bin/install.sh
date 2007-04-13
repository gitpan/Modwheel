#!/bin/bash

DEFAULT_PREFIX=/opt/modwheel

read_password ()
{
    perl -MTerm::ReadKey -le'ReadMode("noecho"); $a = <STDIN>; ReadMode("restore"); print $a'
}
read_input ()
{
    echo -n "$1 [$2]: ";
    read
    if [ -z "$REPLY" ]; then
        if [ ! -z "$3" ]; then
            REPLY="$3"
        else
            REPLY="$2"
        fi
    fi
}
create_dir ()
{
    if [ ! -z "$1" ]; then
        if [ ! -d "$1" ]; then
            mkdir -p "$1"
        fi
    fi
}
save_cache ()
{
    wrln () {
        echo "$1"="\"$2\""
    }
    echo $(wrln prefix          "$prefix")            >  install.cache
    echo $(wrln repository      "$repository")        >> install.cache
    echo $(wrln templates       "$templates")        >> install.cache
    echo $(wrln http_user       "$http_user")        >> install.cache
    echo $(wrln repository_mode "$repository_mode")    >> install.cache
}

OS=$(uname -s);
prefix="$DEFAULT_PREFIX"
if [ -f install.cache ]; then
    . ./install.cache
fi

read_input "Prefix: Where do you want to install Modwheel?" "$prefix"
prefix="$REPLY"
create_dir "$prefix"
create_dir "$prefix/config"
create_dir "$prefix/bin"
cp ./utils/* "$prefix/bin"

read_input "Repository: Where do you want to keep uploaded files?" "$prefix/Repository"
repository="$REPLY"
create_dir "$repository"

read_input "Templates: Where do you want to install templates?" "$prefix/Templates"
templates="$REPLY"
create_dir "$templates"

if   [ "$OS" == "Darwin" ]; then
    http_user='daemon'
elif [ "$OS" == "Linux" ]; then
    http_user='nobody'
elif [ "$OS" == "FreeBSD" ]; then
    http_user='nobody'
else
    http_user='nobody'
fi

read_input "HTTP User: Which user is the http daemon running as (i.e apache)?" "$http_user"

read_input "The Repository directory must be writable by the http user, we can either make the directory writable by all (not recommended) or the httpd user" \
    "user/all" "user"
repository_mode="$REPLY"
case "$repository_mode" in
    user*)
        confirm_repmode="user"
    ;;
    all*)
        confirm_repmode="all"
    ;;
    *)
        echo "Unknown reply. Using default answer 'user'."
        confirm_repmode="user"
    ;;
esac
if [ "$USER" == "root" ]; then
    if   [ "$confirm_repmode" == "user" ]; then
        chown -R "$http_user" "$repository"
    elif [ "$confirm_repmode" == "all" ];  then
        chmod -R 777 "$repository"
    fi
else
    echo "Warning: You are not running this script as root!"
    sudo=$(whereis sudo)
    if [ ! -z "$sudo" ]; then
        
        if   [ "$confirm_repmode" == "user" ]; then
            echo "command: chown -R $http_user \"$repository\""
        elif [ "$confirm_repmode" == "all" ];  then
            echo "command: chmod -R 777 \"$repository\""
        fi
        read_input "You have sudo installed. Do you want to run the command above as root with sudo?" "YES/no" "YES"
        case "$REPLY" in
            [nN]*)
                didnotchownrep=1
            ;;
            [yY]*)
                if   [ "$confirm_repmode" == "user" ]; then
                    $sudo chown -R $http_user "$repository"
                elif [ "$confirm_repmode" == "all" ];  then
                    $sudo chmod -R 777 "$repository"
                fi
            ;;
        esac
    else
        didnotchownrep=1
    fi
fi
if [ ! -z "$didnotchownrep" ]; then
    echo
    echo "You did not make the repository directory writable by the user running the http server."
    echo "Be sure to execute this command as the superuser after this program is finished:"
    if   [ "$confirm_repmode" == "user" ]; then
            echo "    $sudo chown -R $http_user \"$repository\""
    elif [ "$confirm_repmode" == "all" ];  then
            echo "    $sudo sudo chmod -R 777 \"$repository\""
    fi
    echo
fi

read_input "Do you want to copy the default template files to the template directory?" "YES/no" "YES"
case "$REPLY" in
    [yY]*)
        cp -r ./Templates/* "$templates"    
    ;;
esac


read_input "Would you like to configure your sites and set up your database now?" "YES/no" "YES"
case "$REPLY" in
    [yY]*)
        perl ./mwconfig.pl "$prefix/config/modwheelconfig.yml" "$prefix" "$templates" "$repository"
    ;;
esac

pw=$(read_password)
echo $pw
