# sqlocker
Shell script for managing usernames and passwords locally using an encrypted SQLite database.

Allows for easy curation of passwords by service. The encrypted database file can be transfered between computers and will still work.

![image](http://i.imgur.com/dUCxCZv.png)

# Installation

	$ git clone https://github.com/maquchizi/sqlocker.git
	$ cd sqlocker

Requires `sqlcipher` build and install it from [source](https://github.com/sqlcipher/sqlcipher.git).
Clone `sqlcipher` in the sqlocker folder.
```
$ git clone https://github.com/sqlcipher/sqlcipher.git 
$ cd sqlcipher

#ubuntu
$ ./configure --enable-tempstore=yes CFLAGS="-DSQLITE_HAS_CODEC" \
    LDFLAGS="-lcrypto"

#macos
$ ./configure --enable-tempstore=yes CFLAGS="-DSQLITE_HAS_CODEC" \
	LDFLAGS="/usr/local/opt/openssl/lib/libcrypto.a"

$ make
```
# Use

## Create a new database file

To create a new database file (or run the script for the first time), run `./sqlocker.sh name-of-encrypted-database.db` or just `./sqlocker.sh`

If you don't provide a name for your database file, the script will create the default `sqlocker.db` file for you

The `.db` file will be created in the sqlocker directory and locked with the password you provide. That's it. You can now use your new database.

## Working with an existing database file

Run the script with `./sqlocker.sh name-of-encrypted-database.db` or just `./sqlocker.sh` to use the default database

These commands are case insensitive

* Type *c* to create credentials. You will be prompted for a *Service*, *Username*, and *Password*. If you try to create credentials for an already existing service, the script will run the *update* function instead

* Type *r* to read credentials or all passwords. You will be prompted for a *Service*. Default is *all*

* Type *u* to update credentials for an already existing service. You will be prompted for a *Service* then the new *Username* and *Password*

* Type *d* to delete credentials. You will be prompted for a *Service*

After each of these commands, you will be prompted for the database password. Enter the correct password to unlock the database and run operations on it.
The database is automatically encrypted after each operation and is never available in its unencrypted form.

# Extra bits

If you're on a Debian(ish) distro, you can add an alias to your *~/.bashrc* file so that you can run the script from anywhere.

Something like: **alias sqlocker="/path/to/sqlocker/folder/./sqlocker.sh"**

You might need to:
```$ source ~/.bashrc```

Now you can run this from anywhere on your system using:
```$ sqlocker```

#Inspiration

This project was inspired in part by [pwd.sh](https://github.com/drduh/pwd.sh)
