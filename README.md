# sqlocker
Shell script for managing usernames and passwords locally using an encrypted SQLite database.

Allows for easy curation of passwords by service. The encrypted database file can be transfered between computers and will still work.

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

To create a new database file (or run the script for the first time), run `./sqlocker.sh name-of-new-encrypted-database.db`

The `.db` file will be created in your current directory and locked with the password you provide. That's it. You can now use your new database.

## Working with an existing database file

Run the script with `./sqlocker.sh name-of-encrypted-database.db`

These commands are case insensitive

* Type *c* to create credentials. You will be prompted for a *Service*, *Username*, and *Password*. If you try to create credentials for an already existing service, the script will run the *update* function instead

* Type *r* to read credentials or all passwords. You will be prompted for a *Service*. Default is *all*

* Type *u* to update credentials for an already existing service. You will be prompted for a *Service* then the new *Username* and *Password*

* Type *d* to delete credentials. You will be prompted for a *Service*

After each of these commands, you will be prompted for the database password. Enter the correct password to unlock the database and run operations on it.
The database is automatically encrypted after each operation and is never available in its unencrypted form. 

#Inspiration

The project was inspired in part by [pwd.sh](https://github.com/drduh/pwd.sh)