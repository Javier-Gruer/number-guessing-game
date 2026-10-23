#!/bin/bash

# Connect to the number_guess database.
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random secret number between 1 and 1000.
RANDOM_NUMBER=$(( RANDOM % 1000 + 1 ))

# Ask for the username and look up their game history.
echo "Enter your username:"
read USERNAME

USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

# Welcome returning users or register new users.
if [[ -n $USER_INFO ]]; then
  GAMES_PLAYED=$(echo "$USER_INFO" | cut -d '|' -f 1)
  BEST_GAME=$(echo "$USER_INFO" | cut -d '|' -f 2)
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
else
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME')" > /dev/null
fi

# Count every guess, including invalid entries.
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=1
read GUESS

while [[ ! $GUESS =~ ^[0-9]+$ ]] || (( GUESS != RANDOM_NUMBER )); do
  if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  elif (( GUESS > RANDOM_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi

  read GUESS
  ((NUMBER_OF_GUESSES++))
done

# Display the result and update the user's statistics.
echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $RANDOM_NUMBER. Nice job!"

$PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $NUMBER_OF_GUESSES < best_game THEN $NUMBER_OF_GUESSES ELSE best_game END WHERE username='$USERNAME'" > /dev/null
