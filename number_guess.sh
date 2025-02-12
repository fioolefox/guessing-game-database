#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c"

echo "Enter your username:"
read USERNAME

# Ensure username is within the 22-character limit
if [[ ${#USERNAME} -gt 22 ]]; then
  echo "Username must be 22 characters or fewer."
  exit 1
fi

USERNAME_AVAIL=$($PSQL "SELECT username FROM users WHERE username='$USERNAME'" | xargs)
GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM users INNER JOIN games USING(user_id) WHERE username = '$USERNAME'" | xargs)
BEST_GAME=$($PSQL "SELECT MIN(number_guesses) FROM users INNER JOIN games USING(user_id) WHERE username = '$USERNAME'" | xargs)

# Check if username exists
if [[ -z "$USERNAME_AVAIL" || "$USERNAME_AVAIL" == " " ]]; then
  INSERT_USER=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate random number
RANDOM_NUM=$((1 + RANDOM % 1000))
GUESS=0

echo "Guess the secret number between 1 and 1000:"

while true; do
  read NUM

  # Check if input is a valid integer
  if ! [[ $NUM =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment guess count
  GUESS=$((GUESS + 1))

  # Check if the guess is correct
  if [[ $NUM -eq $RANDOM_NUM ]]; then
    echo "You guessed it in $GUESS tries. The secret number was $RANDOM_NUM. Nice job!"
    break
  elif [[ $NUM -gt $RANDOM_NUM ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

# Store game result in the database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'" | xargs)
INSERT_GAME=$($PSQL "INSERT INTO games(number_guesses, user_id) VALUES($GUESS, $USER_ID)")