SimpleGrep
==========

This is a small project to demonstrate the fact that an application that runs on both a modern operating system like Mac OS X 10.7 and a significantly older one such as OPENSTEP 4.2 can share a codebase.

SimpleGrep is a simple wrapper around the grep UNIX utility, allowing you to search the contents of files within a directory for a certain term. 

### W…Why?! ###

Why not?

### Contents ###

* Shared/ : The shared source code

* Mac/ : The 

### Known Issues ###

It seems like ProjectBuilder wants all source files for the project within its main directory.  So to get around this, I'm using symbolic links to the files in Shared/.  
