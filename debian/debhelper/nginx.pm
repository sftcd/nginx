#!/usr/bin/perl
use warnings;
use strict;
use Debian::Debhelper::Dh_Lib;

add_command_options( "dh_auto_test",      "--buildsystem=nginx_mod" );
add_command_options( "dh_auto_configure", "--buildsystem=nginx_mod" );
add_command_options( "dh_auto_build",     "--buildsystem=nginx_mod" );
add_command_options( "dh_auto_install",   "--buildsystem=nginx_mod" );
add_command_options( "dh_auto_clean",     "--buildsystem=nginx_mod" );

insert_after("dh_install", "dh_nginx");

1;
