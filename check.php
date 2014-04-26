#!/bin/env php
<?php

//REQUIRES PHP 5.4.x!

$c = file_get_contents( "manifest.json" );
preg_match( "~\"version\"\:\s*\"([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)\",~im", $c, $m );
list( $major, $minor, $build, $revision ) = array_slice( array_map( function( $x ) { return intval( $x ); }, $m ), 1 );
$matched = $m[0];

$branch = substr( trim( exec( "git branch" ) ), 2 );

if( $branch == "master" )
    ++$revision;
elseif( $branch == "stable" )
    ++$build;

$version = implode( ".", array_map( function( $x ) { return strval( $x ); }, [ $major, $minor, $build, $revision ] ) );
$version = sprintf( "\"version\": \"%s\",", $version );

$c = str_replace( $matched, $version, $c );
//file_put_contents( "manifest.json", $c );

//exec( "git add manifest.json" );

$dirs = [ getcwd() ];
$allowed = [ "py", "json", "php", "js", "coffee" ];

while( sizeof( $dirs ) > 0 )
{
    $dir = array_shift( $dirs );
    
    $handle = opendir( $dir );
    while( ( $entry = readdir( $handle ) ) !== false )
    {
        if( $entry == "." or $entry == ".." )
            continue;
        
        if( is_dir( $entry ) )
        {
            $dirs[] = $entry;
            continue;
        }
        
        $ext = pathinfo( $entry, PATHINFO_EXTENSION );
        
        if( !in_array( $ext, $allowed ) )
            continue;
        
        $path = implode( DIRECTORY_SEPARATOR, [ $dir, $entry ] );
        
        $c = file_get_contents( $path );
        if( strpos( $c, "\r\n" ) !== false or strpos( $c, "\r" ) !== false or strpos( $c, "\t" ) !== false )
        {
            $c = str_replace( [ "\r\n", "\r" ], "\n", $c );
            $c = str_replace( "\t", "    ", $c );
            
            echo $path, " has tabs, Cr, or CrLf chars.", PHP_EOL;
            //file_put_contents( $path, $c );
            //exec( "git add \"{$path}\"" );
        }
    }
}

?>