kernel-bananapi
===============

Overview
--------

This project allows to build a Debian package with a Kernel for the
Banana Pi computer.

The kernel image is a uImage file. All modules needed for booting
are packed into the kernel. Hence a initrd file system is not needed.

The load address of the uImage is 0x40008000.

Patches
-------

A patch is included that makes the kernel reboot automatically
when requested to halt or power off.

