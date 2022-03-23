#!/usr/bin/perl -w
use strict;
use Socket;

my $modelo = shift;
my $cor    = shift;
my $texto  = shift;

my $msg = "$modelo|$cor|$texto";

my $porta_servidor = 1234;
my $ip_servidor = '10.13.100.5';
#my $ip_servidor = '177.47.119.204';

socket(Socket_Handle, PF_INET, SOCK_DGRAM, getprotobyname('udp')) || die $!;
send(Socket_Handle, $msg, 0, sockaddr_in($porta_servidor,  inet_aton ($ip_servidor)));

