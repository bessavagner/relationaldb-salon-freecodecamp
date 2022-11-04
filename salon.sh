#!/bin/bash

PSQL="psql -X --username=bessa --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"

MAIN_MENU() {
    if [[ $1 ]]
    then
        echo -e "\n$1"
    fi

    SERVICES=$($PSQL "select service_id, name from services")
    echo "$SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
    do
        echo "$SERVICE_ID) $SERVICE_NAME"
    done

    read SERVICE_ID_SELECTED

    # If not a number
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
        # Return to home with message
        MAIN_MENU "Please input a number"
    else
        SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
        # If service doesn't exist
        if [[ -z $SERVICE_NAME ]] 
        then
            # Return to home with message
            MAIN_MENU "I could not find that service. What would you like today?"
        else
            SERVICE_NAME_FORMATTED=$(echo $SERVICE_NAME | sed 's/ |/"/')
            BOOK_SERVICE "$SERVICE_ID_SELECTED" "$SERVICE_NAME_FORMATTED"
        fi
    fi
}

BOOK_SERVICE() {
    SERVICE_ID=$1
    SERVICE=$2

    # GET CUSTOMER'S INFO
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
    # if customer doesn't exist
    if [[ -z $CUSTOMER_NAME ]]
    then
        # get new customer name
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME
        CUSTOMER_NAME_FORMATTED=$(echo $CUSTOMER_NAME | sed 's/ |/"/')
        # insert new customer
        INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME_FORMATTED', '$CUSTOMER_PHONE')") 
    fi
    CUSTOMER_NAME_FORMATTED=$(echo $CUSTOMER_NAME | sed 's/ |/"/')
    # get customer_id
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
    # get service name
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID")
    SERVICE_NAME_FORMATTED=$(echo $SERVICE_NAME | sed 's/ |/"/')
    # get time from customer
    echo -e "\nWhat time would you like your $SERVICE, $CUSTOMER_NAME_FORMATTED?"
    # make appointment
    read SERVICE_TIME
    INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID, '$SERVICE_TIME')") 
    echo -e "\nI have put you down for a $SERVICE at $SERVICE_TIME, $CUSTOMER_NAME_FORMATTED.\n"
}

MAIN_MENU