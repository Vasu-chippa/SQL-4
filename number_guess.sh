#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -q -t --no-align -c"

printf 'Enter your username: '
read -r USERNAME || exit 0
ESCAPED_USERNAME=${USERNAME//\'/\'\'}
USER_ID=$( $PSQL "SELECT user_id FROM users WHERE username = '$ESCAPED_USERNAME';" )

if [[ -z $USER_ID ]]; then
  USER_ID=$( $PSQL "INSERT INTO users(username) VALUES('$ESCAPED_USERNAME') RETURNING user_id;" )
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  GAMES_PLAYED=$( $PSQL "SELECT COUNT(*) FROM games WHERE user_id = $USER_ID;" )
  BEST_GAME=$( $PSQL "SELECT MIN(number_of_guesses) FROM games WHERE user_id = $USER_ID;" )
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0
printf 'Guess the secret number between 1 and 1000:\n'

while true; do
  read -r GUESS || exit 0
  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

  if [[ ! $GUESS =~ ^-?[0-9]+$ ]]; then
    printf 'That is not an integer, guess again:\n'
    continue
  fi

  if [[ $GUESS == -* ]]; then
    GUESS_NUMBER=-1
  else
    GUESS_DIGITS=$GUESS
    while [[ ${#GUESS_DIGITS} -gt 1 && $GUESS_DIGITS == 0* ]]; do
      GUESS_DIGITS=${GUESS_DIGITS#0}
    done

    if [[ ${#GUESS_DIGITS} -gt 4 ]] || { [[ ${#GUESS_DIGITS} -eq 4 && $GUESS_DIGITS > 1000 ]]; }; then
      GUESS_NUMBER=1001
    else
      GUESS_NUMBER=$((10#$GUESS_DIGITS))
    fi
  fi

  if (( GUESS_NUMBER == SECRET_NUMBER )); then
    break
  elif (( GUESS_NUMBER > SECRET_NUMBER )); then
    printf "It's lower than that, guess again:\n"
  else
    printf "It's higher than that, guess again:\n"
  fi
done

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
$PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($USER_ID, $NUMBER_OF_GUESSES);" > /dev/null