#!/bin/bash
echo ""
echo "======================================================"
echo "GitHub : https://github.com/eliasd-code"
echo "Youtube : https://www.youtube.com/channel/UCJWsbSIhyyGQtnwHpGcZnrw?view_as=subscriber"
echo "Updated at 07.06.2021"
echo "Dieses skript ersetzt nicht das wissen das du bei der manuellen installation benötigen würdest!"
echo ""
echo "Sei dir sicher das du bereits partitioniert, gemountet und eine aktive internet verbindung aufgebaut hast!"
echo "Tippfehler unbedingt vermeiden!"
echo "Enter oder abbrechen"
read n
echo "Dieses Skript ist in 3 Teilen gegliedert:"
echo "Teil 'a' ist der teil nachdem du Partitioniert hast und geht bis zum chroot."
echo "Teil 'b' geht vom chroot bis in den reboot"
echo "Teil 'c' wird nach dem reboot ausgeführt"
echo ""
echo "Bei welchem Teil bist du ?  a/b/c"
read teil
echo "======================================================"
if [ "$teil" == "a" ]
then
    echo "Teil a"
    pacstrap /mnt base base-devel linux linux-firmware nano dhcpcd bash-completion wpa_supplicant netctl dialog lvm2
    while true
    do
        echo ""
        echo "Nutzt du eine Intel oder Amd CPU? intel/amd"
        read ant
        if [ "$ant" == "intel" ]
        then
            pacman --root /mnt -S intel-ucode
            break
        elif [ "$ant" == "amd" ]
        then
            pacman --root /mnt -S amd-ucode
            break
        else
            echo ""
            echo "Tippfehler"
        fi
    done

    genfstab -Up /mnt > /mnt/etc/fstab
    nano /mnt/etc/fstab
    echo ""
    echo "Datei noch mal ausführen und mit 'b' beantworten"
    arch-chroot /mnt/


elif [ "$teil" == "b" ]
then
    echo "Teil b"
    echo "Wie soll dein PC heißen?"
    read ant
    echo "$ant" > /etc/hostname
    echo LANG=de_DE.UTF-8 > /etc/locale.conf
    nano /etc/locale.gen
    locale-gen
    echo KEYMAP=de-latin1 > /etc/vconsole.conf
    echo FONT=lat9w-16 >> /etc/vconsole.conf
    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
    nano /etc/hosts
    nano /etc/pacman.conf
    pacman -Sy
    mkinitcpio -p linux-lts
    echo "passwort für 'root'"
    passwd
    while true
    do
        echo ""
        lsblk
        echo ""
        echo "Wo soll dein Grub Bootloader installiert werden ? (zb /sda,/sda1,/sdc1)  "
        read grub
        echo "hast du ein EFI oder ein Legacy System?   efi/legacy"
        read bios
        echo ""
        echo Der grub Bootloader wird auf /dev"$grub" installiert
        echo du nutzt ein "$bios" System
        echo "Sind diese Angaben richtig ?   nein/ja"
        echo "auch die groß und kleinschreibung beachten"
        read ant
        if [ "$ant" == "ja" ]
        then
            if [ "$bios" == "efi" ]
            then
                echo "Der name der Boot Partition (--bootloader-id=?)"
                read label
                pacman -S grub efibootmgr
                grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id="$label"
                break

            elif [ "$bios" == "legacy" ]
            then
                pacman -S grub
                grub-install /dev"$grub"
                break
            else
                echo "Tippfehler"
            fi
        fi
    done
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "Bitte System neu starten und dannach Datei neu ausführen"
    echo "Dann 'c' eingeben"
    exit

elif [ "$teil" == "c" ]
then
    echo "Teil c"
    echo "Wie soll dein neuer Benutzer heißen?"
    read ant
    useradd -m -g users -s /bin/bash "$ant"
    echo passwort für "$ant"
    passwd "$ant"
    pacman -S sudo
    nano /etc/sudoers
    gpasswd -a "$ant" wheel
    gpasswd -a "$ant" games
    gpasswd -a "$ant" audio
    gpasswd -a "$ant" video
    systemctl enable --now fstrim.timer
    pacman -S acpid dbus avahi cups cronie
    systemctl enable acpid
    systemctl enable avahi-daemon
    systemctl enable org.cups.cupsd.service
    systemctl enable --now cronie
    systemctl enable --now systemd-timesyncd.service
    date
    hwclock -w
    date
    pacman -S xorg-server xorg-xinit
    echo "Welcher Grafiktreiber soll installiert werden? ;)"
    echo "Für Nvidia Grafikkarten: (nvidia)"
    echo "Für AMD Grafikarten (xf86-video-amdgpu und amdvlk)"
    echo "Enter drücken falls kein Treiber installiert werden soll."
    read ant
    pacman -S "$ant"
    localectl set-x11-keymap de pc105 nodeadkeys
    pacman -S ttf-dejavu
    echo ""
    echo "Diese Script kann dir Standart mäßig den XFCE Desktop mit installieren (meine Empfehlung)"
    echo "Willst du das ?  ja/nein"
    read ant
    if [ "$ant" == "ja" ]
    then
        pacman -S xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings pipewire pipewire-pulse pipewire-alsa piewire-jack pipewire-media-session pavucontrol
        systemctl enable lightdm
    else
        echo "Desktop umgebung wird nicht mit installiert."
    fi
    echo ""
    echo "Willst du das Standart pakete wie 'nmap, firefox, NetworkManager, libreoffice, linux headers, net-tools usw installiert werden ? (meine Empfehlung)"
    echo "verschiedene wichtige fonts und codecs sind auch dabei um spätere software fehler vorzubeugen"
    echo "Wirkt gut gegen Kopfschmerzen ;)"
    echo " ja/nein "
    read ant
    if [ "$ant" == "ja" ]
    then
        pacman -S firefox libreoffice-still nmap net-tools linux-headers gparted unzip git wget xz p7zip vlc okular geeqie ufw iptables networkmanager modemmanager nm-connection-editor network-manager-applet thunderbird gimp adobe-source-sans-pro-fonts aspell-de enchant gst-libav gst-plugins-good hunspell-de icedtea-web jre8-openjdk languagetool libmythes mythes-de pkgstats ttf-anonymous-pro ttf-bitstream-vera ttf-dejavu ttf-droid ttf-liberation ttf-ubuntu-font-family
        systemctl enable NetworkManager.service

    else
        echo "Standart Pakete werden nicht installiert."
    fi

    echo ""
    echo "installation wurde erfolgreich abgeschlossen :)"
    echo "Viel Spaß auf deinem neuen System!"
    echo "Danke"
    read a


else
    echo "Tippfehler.. Bitte nur nüchtern ausführen!"

fi
