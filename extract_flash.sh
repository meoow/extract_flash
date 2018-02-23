#!/bin/bash

extractflash ()
{
    [[ ! -f "$1" ]] && return 1;
    local dmgfile="$1";
    local a b c mp;
    while read a b c; do
        eval mp='$c';
    done < <(hdiutil mount -noautofsck -noverify -noautoopen "$dmgfile"||exit 1);
    firefoxflash="$mp/Install Adobe Flash Player.app/Contents/Resources/Adobe Flash Player.pkg";
    pepperflash="$mp/Install Adobe Pepper Flash Player.app/Contents/Resources/Adobe Flash Player.pkg";
    if [[ -f "$firefoxflash" ]]; then
        flashtype=firefox;
    else
        if [[ -f "$pepperflash" ]]; then
            flashtype=pepper;
        else
            exit 1;
        fi;
    fi;
    echo Step 1;
    if [[ "$flashtype" == firefox ]]; then
        7z x -so "$firefoxflash" 'AdobeFlashPlayerComponent.pkg/Payload' | cpio -id './Library/Internet Plug-Ins';
    else
        7z x -so "$pepperflash" 'AdobeFlashPlayerComponent.pkg/Payload' | cpio -id './Library/Internet Plug-Ins';
    fi;
    ((PIPESTATUS[0]!=0)) && return 1;
    echo Step 2;
    if [[ "$flashtype" == firefox ]]; then
        7z x -so "$firefoxflash" 'AdobeFlashPlayerComponent.pkg/Scripts' | cpio -id './finalize';
    else
        7z x -so "$pepperflash" 'AdobeFlashPlayerComponent.pkg/Scripts' | cpio -id './finalize';
    fi;
    ((PIPESTATUS[0]!=0)) && return 1;
    ./finalize . && rm ./finalize;
    if [[ ! -d $HOME/'Library/Internet Plug-Ins' ]]; then
        mkdir $HOME/'Library/Internet Plug-Ins' || return 1;
    fi;
    if [[ "$flashtype" == firefox ]]; then
        rm -rf $HOME'/Library/Internet Plug-Ins/Flash Player.plugin';
        rm -rf $HOME'/Library/Internet Plug-Ins/flashplayer.xpt';
        mv 'Library/Internet Plug-Ins/Flash Player.plugin' $HOME/'Library/Internet Plug-Ins/' || return 1;
        mv 'Library/Internet Plug-Ins/flashplayer.xpt' $HOME/'Library/Internet Plug-Ins/' || return 1;
    else
        rm -rf $HOME'/Library/Internet Plug-Ins/PepperFlashPlayer';
        mv 'Library/Internet Plug-Ins/PepperFlashPlayer' $HOME/'Library/Internet Plug-Ins/' || return 1;
    fi;
    rmdir 'Library/Internet Plug-Ins';
    rmdir 'Library';
    hdiutil unmount "$mp";
    echo All done.
}

extractflash "$@"
