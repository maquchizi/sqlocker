#!/bin/bash
DATABASE=$1

set -euf -o pipefail

sqlcipher=$(command -v sqlcipher)

error () {
    printf "\n\n"
    echo -e "\e[31mError: ${1}\e[0m"
    exit 1
}

enter_password () {
    password=''
    prompt="${1}"
    while IFS= read -p "${prompt}" -r -s -n 1 char ; do
        if [[ ${char} == $'\0' ]] ; then
            break
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

read_pass () {
    if [[ -z ${service} || ${service} == "all" ]] ; then
        enter_password "Enter password to unlock ${DATABASE}:"
        printf "\n\n"
        sqlcipher ${DATABASE} -line -header "PRAGMA key = \"${password}\"; SELECT * FROM credentials;"
    else
       enter_password "Enter password to unlock ${DATABASE}:"
       printf "\n\n"
       sqlcipher ${DATABASE} -line -header "PRAGMA key = \"${password}\"; SELECT * FROM credentials WHERE service=\"${service}\";"
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
    if [[ "${result}" =~ ([${service}]) ]] ; then
        sqlcipher ${DATABASE} "PRAGMA key = \"${password}\"; UPDATE credentials SET username = '${username}', password = '${providedpassword}' WHERE service = '${service}';"
        echo "${service} Credentials Updated"
    else
        sqlcipher ${DATABASE} "PRAGMA key = \"${password}\"; INSERT INTO credentials values('${service}','${username}','${providedpassword}');"
        echo "${service} Credentials Created"
    fi
}

delete_credentials () {
    if [ -z ${service} ] ; then
        error "No service was selected"
    else
        enter_password "Enter password to unlock ${DATABASE}:"
        printf "\n\n"
        sqlcipher ${DATABASE} "PRAGMA key = \"${password}\"; DELETE FROM credentials WHERE service=\"${service}\";"
        echo "${service} Credentials Created"
    fi
}

create_database () {
    echo "Creating Database..."
    enter_password "Enter password for ${DATABASE}:"
    printf "\n\n"
    sqlcipher ${DATABASE} "PRAGMA key = \"${password}\"; CREATE TABLE credentials(service text,username text,password text);"
    echo "Creating Database..."
    echo "Done"
    main
}

main () {
    echo -n -e "\e[4mC\e[0mreate, \e[4mR\e[0mead, \e[4mU\e[0mpdate or \e[4mD\e[0melete credentials? (C/R/U/D, default: R) "
    read -n 1 action
    printf "\n"

    if [[ "${action}" =~ ^([cCuU])$ ]] ; then
        create_credentials && save_credentials
    elif [[ "${action}" =~ ^([dD])$ ]] ; then
        read -p "Service to delete? " service && delete_credentials
    else
        read -p "Service to read? (default: all) " service && read_pass
    fi
}

init () {
    if [[ -z ${sqlcipher} && ! -x ${sqlcipher} ]] ; then
        fail "Please install sqlcipher"
    fi

    if [ -z ${DATABASE} ] ; then
        echo "Please select a credentials database"
        exit 1
    fi

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