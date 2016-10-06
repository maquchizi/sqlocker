#!/usr/bin/env bash
SQLOCKERDIRECTORY=$( cd "$(dirname "${BASH_SOURCE}")" ; pwd -P )
cd "$SQLOCKERDIRECTORY"

DATABASE=$1

# Default to a database named sqlocker.db
if [ -z ${1} ] ; then
    DATABASE="sqlocker.db"
else
    DATABASE=$1
fi

set -euf -o pipefail
sqlcipher=$(command -v sqlcipher)

error () {
    printf "\n\n"
    echo -e "\e[31mError: ${1}\e[0m"
    exit 1
}

# Read and obfuscate any passwords entered on the script
enter_password () {
    password=''
    prompt="${1}"
    while IFS= read -p "${prompt}" -r -s -n 1 char ; do
        # If you hit "Enter"
        if [[ ${char} == $'\0' ]] ; then
            break
        # If you hit "Delete"
        elif [[ ${char} == $'\177' ]] ; then
            if [[ -z "${password}" ]] ; then
                prompt=""
            else
                prompt=$'\b \b'
                password="${password%?}"
            fi
        else
            prompt="*"
            password+="${char}"
        fi
    done

    if [[ -z ${password} ]] ; then
        error "No password provided"
    fi
}

read_password () {
    if [[ -z ${service} || ${service} == "all" ]] ; then
        enter_password "Enter password to unlock ${DATABASE}:"
        printf "\n\n"
        sqlcipher ${DATABASE} -column -header ".width 20 30 40;" "PRAGMA key = \"${password}\"; SELECT * FROM credentials;"
    else
       enter_password "Enter password to unlock ${DATABASE}:"
       printf "\n\n"
       sqlcipher ${DATABASE} -column -header ".width 20 30 40;" "PRAGMA key = \"${password}\"; SELECT * FROM credentials WHERE service=\"${service}\";"
   fi
}

create_credentials () {
    read -p "
    Service: " service
    read -p "
    Username: " username 
    enter_password "
    Enter password for \"${service}\": " ; echo
    providedpassword=$password
}

save_credentials () {
    enter_password "Enter password to unlock ${DATABASE}:"
    printf "\n\n"
    result=$(sqlcipher ${DATABASE} -line "PRAGMA key = \"${password}\"; SELECT * FROM credentials WHERE service=\"${service}\";")

    # If the service entered already exists in the DB, update the record else create a new record
    if [[ "${result}" =~ ([${service}]) ]] ; then
        sqlcipher ${DATABASE} "PRAGMA key = \"${password}\"; UPDATE credentials SET username = '${username}', password = '${providedpassword}' WHERE service = '${service}';"
        echo "${service} Credentials Updated"
    else
        sqlcipher ${DATABASE} "PRAGMA key = \"${password}\"; INSERT INTO credentials values('${service}','${username}','${providedpassword}');"
        echo "${service} Credentials Created"
    fi
}

delete_credentials () {
    # If no service was entered
    if [ -z ${service} ] ; then
        error "No service was selected"
    else
        enter_password "Enter password to unlock ${DATABASE}:"
        printf "\n\n"
        sqlcipher ${DATABASE} "PRAGMA key = \"${password}\"; DELETE FROM credentials WHERE service=\"${service}\";"
        echo "${service} Credentials Deleted"
    fi
}

create_database () {
    enter_password "Enter password for ${DATABASE}:"
    printf "\n\n"
    sqlcipher ${DATABASE} "PRAGMA key = \"${password}\"; CREATE TABLE credentials(service text,username text,password text);"
    echo "Creating Database..."
    echo "Done"
    main
}

main () {
    echo -n -e "\e[4mC\e[0mreate, \e[4mR\e[0mead, \e[4mU\e[0mpdate or \e[4mD\e[0melete credentials? (c/r/u/d, default: r) "
    read -n 1 action
    printf "\n"

    if [[ "${action}" =~ ^([cCuU])$ ]] ; then
        create_credentials && save_credentials
    elif [[ "${action}" =~ ^([dD])$ ]] ; then
        read -p "Service to delete? " service && delete_credentials
    else
        read -p "Service to read? (default: all) " service && read_password
    fi
}

init () {
    # If sqlcipher is not installed or not executable
    if [[ -z ${sqlcipher} && ! -x ${sqlcipher} ]] ; then
        fail "Please install sqlcipher"
    fi

    # If the database name was not provided
    if [ -z ${DATABASE} ] ; then
        echo "Please select a credentials database"
        exit 1
    fi

    # If the database name was provided but is not present in the current directory
    if [ ! -f ${DATABASE} ] ; then
        read -n 1 -p "Database doesn't exists. Should I create it for you? (y/n) " action
        printf "\n"
        if [[ "${action}" =~ ^([yY])$ ]] ; then
            create_database
        else
            echo "Okay. Bye."
            exit 1
        fi
    else
        main
    fi
}

init