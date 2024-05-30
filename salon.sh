#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~"

MAIN_MENU() {
  FLAG="false"
  while true
  do
    if [[ $FLAG == "false" ]]
    then
      echo -e "\nWelcome to My Salon, how can I help you?\n"
    else
      echo -e "\nI could not find that service. What would you like today?"
    fi

    # 列出服务列表
    SERVICES_RESULT=$($PSQL "SELECT * FROM services")
    echo "$SERVICES_RESULT" | while read SERVICE_ID BAR SERVICE_NAME
    do
      echo "$SERVICE_ID) $SERVICE_NAME"
    done

    # 选择服务
    read SERVICE_ID_SELECTED

    # 如果是个非法输入，或者输入的服务号不在列表
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ || -z $($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED") ]]
    then
      # FLAG改为true
      FLAG="true"
      continue
    else
      # 进入登记流程
      REGISTER $SERVICE_ID_SELECTED
      break
    fi
  done
}

REGISTER() {
  # 获得服务名
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$1")
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE
  # 查询电话对应的客户名
  SEARCH_CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
  # 如果没有找到客户名
  if [[ -z $SEARCH_CUSTOMER_NAME ]]
  then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME
    # 插入新客户信息到customers
    INSERT_NEW_CUSTOMER=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
    echo -e "\nWhat time would you like your $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')?"
  # 找到客户名
  else
    echo -e "\nWhat time would you like your $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g'), $(echo $SEARCH_CUSTOMER_NAME | sed -r 's/^ *| *$//g')?"
  fi
  # 获得客户id
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")

  # 读取预约时间
  read SERVICE_TIME
  # 预约插入appointments
  INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $1, '$SERVICE_TIME')")
  echo -e "\nI have put you down for a $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g') at $(echo $SERVICE_TIME | sed -r 's/^ *| *$//g'), $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
}

MAIN_MENU