/*
    Chizzy
 I'm making a block breaker type game that I saw on google
 
 The mechanics in this game will be
 - Moving paddle that can hit the moving ball
 - Rectangles that will increase the player's score if hit
 - Score
 - Retry button
 */

// Variables
boolean roundStarted = false;
boolean ballInPlay = false;

boolean leftPressed = false;
boolean rightPressed = false;
boolean gameOver = false;
boolean gamePaused = false;

PFont fontBold;
PFont fontNormal;

int score = 0;
int lastScore = score;
int highscore = score;

// Buttons
int startButtonX = 125, startButtonY = 340, startButtonWidth = 350, startButtonHeight = 100;
int paddleX = 200, paddleY = 480, paddleWidth = 150, paddleHeight = 15;

int playAgainX = 165, playAgainY = 410, playAgainWidth = 240, playAgainHeight = 50;

int pauseButtonX = 520, pauseButtonY = 10, pauseButtonWidth = 50, pauseButtonHeight = 50;

// Bouncing ball
ArrayList<Ball> balls = new ArrayList<Ball>();

// Blocks
int startBlockX = 90, startBlockY = 60;
int blockX = startBlockX, blockY = startBlockY, blockWidth = 50, blockHeight = 25, blockdiameter = 10;
boolean blocksLoaded = false;

// Configurations
int screenWidth = 600, screenHeight = 600;
int paddleSpeed = 10;
int maxLives = 3;
int livesCount = maxLives;

boolean blockCollisionDebounce = false;
int blockResetCollisionCooldown = 900;
float blockGraceEnd = 0;
float lastBlockCollision;
float collisionCooldown = 80;

int blockMaxCount = 28;
int blockColumns = 7;
int blockSpacingX = 55, blockSpacingY = 30;
int blockCount = blockMaxCount;
int currentBlock = 0;
int blockPointsWorth = 50;

// Special block
int currentSpecialBlockIndex = 0;

boolean[] blockAlive = new boolean[blockMaxCount];
int[] specialBlocks = new int[3];

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
  }

  for (int i = 0; i < 28; i++) {
    if (random(0, 100) < 10 && currentSpecialBlockIndex < specialBlocks.length) {
      specialBlocks[currentSpecialBlockIndex] = i;
      currentSpecialBlockIndex++;
    }
  }

  balls.add(new Ball(
    paddleX + paddleWidth / 2,
    paddleY - 25,
    4,
    -4,
    25
    ));
}

void gameOver() {
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

boolean isSpecialBlock(int blockIndex) {
  for (int i = 0; i < specialBlocks.length; i++) {
    if (specialBlocks[i] == blockIndex) {
      return true;
    }
  }
  return false;
}

void resetBall() {
  paddleX = 200;
  paddleY = 480;
  ballInPlay = false;
  balls.clear();

  // Restart position of ball
  balls.add(new Ball(
    paddleX + paddleWidth / 2,
    paddleY - 25,
    4,
    -4,
    25
    ));

  blockGraceEnd = millis() + blockResetCollisionCooldown;
}

void resetBlocks() {
  strokeWeight(0);
  blockCount = blockMaxCount;
  for (int i = 0; i < blockMaxCount; i++) {
    blockAlive[i] = true;
  }
}

void draw() {
  background(20);

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

    // Update ball position
    if (!ballInPlay) {
      for (int ballIndex = 0; ballIndex < balls.size(); ballIndex++) {
        Ball ball = balls.get(ballIndex);

        ball.ballX = paddleX + paddleWidth / 2;
        ball.ballY = paddleY - 25;
      }

      fill(255);
      textAlign(CENTER);
      text("Press [W] key to begin", 300, 300);
    }

    // Create the paddle
    fill(255);
    rect(paddleX, paddleY, paddleWidth, paddleHeight, 15);

    // Add lives
    for (int i = 1; i <= livesCount; i++) {
      // Got this image from Flaticon
      image(livesIcon, livesX * i * 2, livesY);
    }

    // Score Text
    textFont(fontNormal);
    fill(255);
    text(score, 275, 40);

    if (millis() >= blockGraceEnd) {
      for (int ballIndex = 0; ballIndex < balls.size(); ballIndex++) {
        Ball ball = balls.get(ballIndex);

        // Block collision debounce
        if (millis() - lastBlockCollision >= collisionCooldown) {
          ball.hitDebounce = false;
        }

        // Update and display balls
        if (balls.size() > 0) {
          ball.update();
          ball.display();
        }

        // Player lost a life
        if (ball.ballY + ball.diameter > screenHeight) {
          balls.remove(ball);
          if (balls.size() <= 0) {
            livesCount--;
            resetBall();
            if (livesCount <= 0) {
              gameOver();
            }
          }
        }
      }
    }

    // Load blocks
    for (int blockIndex = 0; blockIndex < blockMaxCount; blockIndex++) {

      if (!blockAlive[blockIndex]) continue;

      int col = blockIndex % blockColumns;
      int row = blockIndex / blockColumns;

      int x = startBlockX + col * blockSpacingX;
      int y = startBlockY + row * blockSpacingY;

      strokeWeight(3);

      color baseColor;
      color baseStroke;
      if (blockIndex < 7) {
        // Yellow
        baseColor = color(210, 198, 45);
        baseStroke = color(158, 138, 24);
      } else if (blockIndex < 14) {
        // Green
        baseColor = color(2, 161, 23);
        baseStroke = color(7, 140, 25);
      } else if (blockIndex < 21) {
        // Red
        baseColor = color(255, 59, 59);
        baseStroke = color(209, 44, 44);
      } else if (blockIndex > 20) {
        // Blue
        baseColor = color(42, 128, 209);
        baseStroke = color(40, 100, 156);
      } else {
        baseColor = color(0);
        baseStroke = color(0);
      }
      // Darken the block if its special
      if (isSpecialBlock(blockIndex)) {
        // Special block
        baseColor = lerpColor(baseColor, color(0), 0.25);
        baseStroke = lerpColor(baseColor, color(0), 0.25);
      }

      fill(baseColor);
      stroke(baseStroke);

      rect(x, y, blockWidth, blockHeight, 10);
    }

    for (int b = 0; b < balls.size(); b++) {
      Ball ball = balls.get(b);
      if (ball.hitDebounce) continue;

      float radius = ball.diameter / 2.0;

      // Ball and block collision
      for (int bb = 0; bb < blockMaxCount; bb++) {
        if (!blockAlive[bb]) {
          continue;
        }

        int col = bb % blockColumns;
        int row = bb / blockColumns;

        float x = startBlockX + col * blockSpacingX;
        float y = startBlockY + row * blockSpacingY;

        // Closest point on the block rectangle to the ball's center
        float closestX = constrain(ball.ballX, x, x + blockWidth);
        float closestY = constrain(ball.ballY, y, y + blockHeight);

        float dx = ball.ballX - closestX;
        float dy = ball.ballY - closestY;
        float distSq = dx * dx + dy * dy;

        if (distSq < radius * radius) {
          // Calculate how far the ball overlaps horizontally and vertically
          float overlapLeft   = (ball.ballX + radius) - x;
          float overlapRight  = (x + blockWidth) - (ball.ballX - radius);
          float overlapTop    = (ball.ballY + radius) - y;
          float overlapBottom = (y + blockHeight) - (ball.ballY - radius);

          float minOverlapX = min(overlapLeft, overlapRight);
          float minOverlapY = min(overlapTop, overlapBottom);

          if (minOverlapX < minOverlapY) {
            if (overlapLeft < overlapRight) {
              ball.ballX = x - radius;
            } else {
              ball.ballX = x + blockWidth + radius;
            }
            ball.speedX *= -1;
          } else {
            if (overlapTop < overlapBottom) {
              ball.ballY = y - radius;
            } else {
              ball.ballY = y + blockHeight + radius;
            }
            ball.speedY *= -1;
          }

          // Debounce
          ball.hitDebounce = true;
          lastBlockCollision = millis();

          // Destroy block
          blockAlive[bb] = false;
          blockCount--;
          score += blockPointsWorth;

          // Special block effect
          if (isSpecialBlock(bb)) {
            createBall(x + blockWidth / 2.0, y + blockHeight / 2.0);
            break;
          }

          break;
        }
      }
    }

    // Player got all the blocks
    if (blockCount <= 0) {
      blockCount = 0;
      resetBlocks();
    }
  }

  // Pause button
  if (roundStarted) {

    fill(120);
    stroke(90);
    rect(pauseButtonX, pauseButtonY, pauseButtonWidth, pauseButtonHeight);
    fill(255);
    stroke(0);
    strokeWeight(2);
    rect(pauseButtonX + 13, pauseButtonY + 10, 7, 30, 10);
    rect(pauseButtonX + 30, pauseButtonY + 10, 7, 30, 10);
  }
  if (gamePaused) {
    fill(120);
    rect(120, 150, 350, 250, 12);
    fill(255);
    textAlign(CENTER);
    textFont(fontBold);
    text("Paused", 300, 225);
    
    textSize(36);
    // Show the score
    text("[E] to continue", 300, 320);
  }

  if (gameOver) {
    background(20);
    fill(120);
    rect(120, 150, 350, 250, 12);

    fill(255);
    textAlign(CENTER);
    textFont(fontBold);
    text("GAME OVER", 300, 225);

    textSize(20);
    // Show the score
    text("Score", 190, 320);
    text(lastScore, 190, 345);

    // Highscore
    text("Highscore", 360, 320);

    text(highscore, 360, 345);

    // Create "Play again" button
    rect(playAgainX, playAgainY, playAgainWidth, playAgainHeight, 15);
    fill(0);
    textSize(32);
    text("Play Again", playAgainX + 125, 445);
  }
}

void createBall(float spawnX, float spawnY) {
  float randomSpeedX = random(-5, 5);
  float randomSpeedY = random(-7, -4);

  Ball newBall = new Ball(
    spawnX,
    spawnY,
    randomSpeedX,
    randomSpeedY,
    25
    );

  balls.add(newBall);
}

// Paddle movement
void keyPressed() {

  if (Character.toLowerCase(key) == 'd' || keyCode == RIGHT) {
    rightPressed = true;
  } else if (Character.toLowerCase(key) == 'a' || keyCode == LEFT) {
    leftPressed = true;
  } else if (Character.toLowerCase(key) == 'w' || keyCode == UP) {

    if (!ballInPlay && roundStarted) {
      ballInPlay = true;
    }
  } else if (Character.toLowerCase(key) == 'e') {
   gamePaused = false; 
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

  // Pressed pause
  if (mouseX >= pauseButtonX && mouseX <= pauseButtonX + pauseButtonWidth
    && mouseY >= pauseButtonY && mouseY <= pauseButtonY + pauseButtonHeight
    && roundStarted) {
    gamePaused = true;
  }
}

class Ball {
  float ballX, ballY;
  float speedX, speedY;
  int diameter = 25;
  boolean hitDebounce = false;

  Ball(float ballX, float ballY, float speedX, float speedY, int diameter) {
    this.ballX = ballX;
    this.ballY = ballY;
    this.speedX = speedX;
    this.speedY = speedY;
    this.diameter = diameter;
    this.hitDebounce = hitDebounce;
  }

  void update() {
    if (gamePaused) {
     return;
    }
    ballX += speedX;
    ballY += speedY;

    float radius = diameter / 2.0;

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

      float upwardSpeed = 5.0;
      speedY = -upwardSpeed;

      ballY = paddleY - radius;
    }
  }

  void display() {
    fill(255);
    circle(ballX, ballY, diameter);
  }
}
