/*
   Chizzy
 I'm making a block breaker type game that I saw on google
 
 The mechanics in this game will be
 - Moving paddle that can hit the moving ball
 - Rectangles that will increase the player's score if hit
 - Score
 - Retry button
 */

// References

// Variables
boolean roundStarted = false;
boolean ballInPlay = false;

boolean leftPressed = false;
boolean rightPressed = false;
boolean gameOver = false;

PFont fontBold;
PFont fontNormal;

int score = 0;
int lastScore = score;
int highscore = score;
int maxLives = 1;
int livesCount = maxLives;

// Buttons
int startButtonX = 125, startButtonY = 340, startButtonWidth = 350, startButtonHeight = 100;
int paddleX = 200, paddleY = 480, paddleWidth = 150, paddleHeight = 15;

int playAgainX = 150, playAgainY = 410, playAgainWidth = 240, playAgainHeight = 50;

// Bouncing ball
ArrayList<Ball> balls = new ArrayList<Ball>();

// Blocks
int startBlockX = 90, startBlockY = 60;
int blockX = startBlockX, blockY = startBlockY, blockWidth = 50, blockHeight = 25, blockRadius = 10;
boolean blocksLoaded = false;

// Configurations
int screenWidth = 600, screenHeight = 600;
int paddleSpeed = 10;

boolean blockCollisionDebounce = false;
float lastBlockCollision;
float collisionCooldown = 250;

int blockMaxCount = 28;
int blockColumns = 7;
int blockSpacingX = 55, blockSpacingY = 30;
int blockCount = blockMaxCount;
int blockPointsWorth = 50;

// Special block
int currentSpecialBlockIndex = 0;

boolean[] blockAlive = new boolean[blockMaxCount];
int[] specialBlocks = new int[6];

PImage livesIcon;
int livesX = 20, livesY = 20;

void setup() {
  size(600, 600);
  background(20);
  livesIcon = loadImage("love-always-wins.png");
  fontBold = createFont("Arial Bold", 42);
  fontNormal = createFont("Arial", 32);

  // Load data
  JSONObject obj = loadJSONObject("highscore.json");
  if (obj != null) {
    highscore = obj.getInt("highscore");
  }

  for (int i = 0; i < blockMaxCount; i++) {
    blockAlive[i] = true;

    // 25% chance to have a special ball
    if (random(0, 100) < 25 && currentSpecialBlockIndex < specialBlocks.length) {
      specialBlocks[currentSpecialBlockIndex] = i;
      currentSpecialBlockIndex++;
      println("Special block : " + currentSpecialBlockIndex);
    }
  }

  balls.add(new Ball(
    4,
    -4,
    0,
    25
    ));
}

void gameOver() {
  println("Player has lost all their lives!");
  livesCount = maxLives;
  resetBlocks();
  gameOver = true;
  roundStarted = false;
  lastScore = score;

  // Save the highscore
  if (score > highscore) {
    highscore = score;
    JSONObject obj = new JSONObject();
    obj.setInt("highscore", score);
    saveJSONObject(obj, "highscore.json");
  }

  score = 0;
}

void resetBall() {
  paddleX = 200;
  paddleY = 480;
  
  balls.clear();

  // Restart position of ball
  balls.add(new Ball(
    paddleX + paddleWidth / 2,
    paddleY - 25,
    4,
    -4,
    0,
    25
  ));
}

void resetBlocks() {
  strokeWeight(0);
  blockCount = blockMaxCount;
  for (int i = 0; i < blockMaxCount; i++) {
    blockAlive[i] = true;
  }
}

void draw() {

  if (!roundStarted && !gameOver) {
    // Title
    textSize(64);
    fill(255);
    text("Block Breaker", 125, 100);
    rect(startButtonX, startButtonY, startButtonWidth, startButtonHeight, 15);
    textSize(55);
    fill(0);
    text("Start", 235, 410);
  }
  // Starting the game
  if (roundStarted) {
    // Paddle movement
    if (rightPressed && paddleX < screenWidth - paddleWidth) {
      paddleX += paddleSpeed;
    }

    if (leftPressed && paddleX > 0) {
      paddleX -= paddleSpeed;
    }

    // Block collision debounce
    if (blockCollisionDebounce) {
      if (millis() - lastBlockCollision >= collisionCooldown) {
        blockCollisionDebounce = false;
      }
    }
    background(20);
    // Create the paddle
    fill(255);
    rect(paddleX, paddleY, paddleWidth, paddleHeight, 15);

    // Add lives
    for (int i = 1; i <= livesCount; i++) {
      image(livesIcon, livesX * i * 2, livesY);
    }

    for (int i = balls.size() - 1; i >= 0; i--) {

      Ball ball = balls.get(i);

      ball.update();
      ball.display();

      // Check if ball fell off screen
      if (ball.ballY - ball.radius > screenHeight) {
        balls.remove(i);
      }
    }
    textFont(fontNormal);

    // Score Text
    fill(255);
    text(score, 275, 40);

    // Load the blocks
    for (int i = 0; i < blockMaxCount; i++) {

      if (!blockAlive[i]) {
        continue;
      }
      int col = i % blockColumns;
      int row = i / blockColumns;

      // Positions
      int x = startBlockX + col * blockSpacingX;
      int y = startBlockY + row * blockSpacingY;
      fill(210, 198, 45);

      // Setting the colors of the block
      strokeWeight(3);
      if (i >= 0 && i < 7) {
        // Yellow
        fill(210, 198, 45);
        stroke(158, 138, 24);
      } else if (i > 0 && i < 14) {
        // Green
        fill(2, 161, 23);
        stroke(7, 140, 25);
      } else if (i > 0 && i < 21) {
        // Red
        fill(255, 59, 59);
        stroke(209, 44, 44);
      } else if (i > 0 && i < 28) {
        // Blue
        fill(42, 128, 209);
        stroke(40, 100, 156);
      }

      rect(x, y, blockWidth, blockHeight, 10);

      // Collision with the ball


      for (int b = 0; b < balls.size(); b++) {

        Ball ball = balls.get(b);

        if (
          ball.ballX + ball.radius > x &&
          ball.ballX - ball.radius < x + blockWidth &&
          ball.ballY + ball.radius > y &&
          ball.ballY - ball.radius < y + blockHeight
          ) {

          // Calculate collision direction
          float deltaX = ball.ballX - (x + blockWidth / 2.0);
          float deltaY = ball.ballY - (y + blockHeight / 2.0);

          float scaleX = (float) blockHeight / blockWidth;
          float scaleY = 1;

          deltaX *= scaleX;
          deltaY *= scaleY;

          if (abs(deltaX) > abs(deltaY)) {
            ball.speedX *= -1;
          } else {
            ball.speedY *= -1;
          }

          // Spawn a bonus ball if this is a special block
          for (int index = 0; index < currentSpecialBlockIndex; index++) {

            if (specialBlocks[index] == i) {
              createBall(ball.ballX, ball.ballY);
              break;
            }
          }

          // Destroy block
          blockAlive[i] = false;
          blockCount--;

          score += blockPointsWorth;

          if (blockCount <= 0) {
            resetBlocks();
          }

          break;
        }
      }


      // Destroy the block
      blockAlive[i] = false;
      blockCount -= 1;
      blockCollisionDebounce = true;
      lastBlockCollision = millis();

      score += blockPointsWorth;

      println("Block count: " + blockCount);

      // Player got all the blocks
      if (blockCount <= 0) {
        blockCount = 0;
        resetBlocks();
      }
      break;
    }
  }

  if (gameOver) {
    background(20);
    fill(120);
    rect(100, 150, 350, 250, 12);

    fill(255);
    textFont(fontBold);
    text("GAME OVER", 135, 225);

    textSize(20);
    // Show the score
    text("Score", 170, 320);
    text(lastScore, 185, 345);

    // Highscore
    text("Highscore", 285, 320);
    text(highscore, 320, 345);

    // Create "Play again" button
    rect(playAgainX, playAgainY, playAgainWidth, playAgainHeight, 15);
    fill(0);
    textSize(32);
    text("Play Again", 195, 445);
  }
}
void createBall(float spawnX, float spawnY) {

  float randomSpeedX = random(-5, 5);
  float randomSpeedY = random(-7, -4);
  float randomGravity = random(0.05, 0.20);

  Ball newBall = new Ball(
    spawnX,
    spawnY,
    randomSpeedX,
    randomSpeedY,
    randomGravity,
    15
    );

  balls.add(newBall);
}

// Paddle movement
void keyPressed() {
  // Move the paddle right
  if (Character.toLowerCase(key) == 'd' || keyCode == RIGHT) {
    rightPressed = true;
  } else if (Character.toLowerCase(key) == 'a' || keyCode == LEFT) {
    // Move it left
    leftPressed = true;
  }
}

void keyReleased() {
  if (Character.toLowerCase(key) == 'a' || keyCode == LEFT) {
    leftPressed = false;
  } else if (Character.toLowerCase(key) == 'd' || keyCode == RIGHT) {
    rightPressed = false;
  }
}

void mousePressed() {

  print("MouseX: " + mouseX + " ");
  print("MouseY " + mouseY);

  // Start button
  if (mouseX >= startButtonX &&
    mouseX <= startButtonX + startButtonWidth &&
    mouseY >= startButtonY &&
    mouseY <= startButtonY + startButtonHeight && !roundStarted) {
    roundStarted = true;
  }

  // Pressed play again
  if (mouseX >= playAgainX && mouseX <= playAgainX + playAgainWidth
    && mouseY >= playAgainY && mouseY <= playAgainY + playAgainHeight
    && gameOver) {
    roundStarted = true;
    gameOver = false;
  }
}

class Ball {
  float ballX, ballY;
  float speedX, speedY;
  int radius = 25;

  Ball(float ballX, float ballY, float speedX, float speedY) {
    this.ballX = ballX;
    this.ballY = ballY;
    this.speedX = speedX;
    this.speedY = speedY;
    this.radius = radius;
  }

  void update() {
    ballX += speedX;
    ballY += speedY;

    if (ballX - radius < 0) {
      ballX = radius;
      speedX *= -1;
    }

    // Ball hitting the right wall
    if (ballX + radius > screenWidth) {
      ballX = screenWidth - radius;
      speedX *= -1;
    }

    // Hitting the top
    if (ballY - radius < 0) {
      ballY = radius;
      speedY *= -1;
    }

    // Ball and paddle collision
    if (ballX >= paddleX && ballX <= paddleX + paddleWidth &&
      ballY + radius >= paddleY && ballY <= paddleY + paddleHeight && speedY > 0) {

      float paddleCenterX = paddleX + (paddleWidth / 2.0);
      float hitOffset = ballX - paddleCenterX;
      float normalizedHit = hitOffset / (paddleWidth / 2.0);

      float maxHorizontalSpeed = 6.0;
      speedX = normalizedHit * maxHorizontalSpeed;

      float upwardSpeed = 6.0;
      speedY = -upwardSpeed;

      ballY = paddleY - radius;
    }

    // Player lost a life
    if (ballY + radius > screenHeight) {
      resetBall();

      livesCount -= 1;
      if (livesCount <= 0) {
        gameOver();
      }
    }
  }

  void display() {
    fill(255);
    circle(ballX, ballY, radius);
  }
}
