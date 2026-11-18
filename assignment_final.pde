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
int maxLives = 5;
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
      println("Special block : " + i);
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

    // Create the paddle
    fill(255);
    rect(paddleX, paddleY, paddleWidth, paddleHeight, 15);

    // Add lives
    for (int i = 1; i <= livesCount; i++) {
      image(livesIcon, livesX * i * 2, livesY);
    }

    // Score Text
    textFont(fontNormal);
    fill(255);
    text(score, 275, 40);

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
      if (ball.ballY + ball.radius > screenHeight) {
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

    for (int blockIndex = 0; blockIndex < blockMaxCount; blockIndex++) {

      if (!blockAlive[blockIndex]) continue;

      int col = blockIndex % blockColumns;
      int row = blockIndex / blockColumns;

      int x = startBlockX + col * blockSpacingX;
      int y = startBlockY + row * blockSpacingY;

      strokeWeight(3);

      if (blockIndex < 7) {
        fill(210, 198, 45);
        stroke(158, 138, 24);
      } else if (blockIndex < 14) {
        fill(2, 161, 23);
        stroke(7, 140, 25);
      } else if (blockIndex < 21) {
        fill(255, 59, 59);
        stroke(209, 44, 44);
      } else {
        fill(42, 128, 209);
        stroke(40, 100, 156);
      }

      rect(x, y, blockWidth, blockHeight, 10);
    }

    for (int b = 0; b < balls.size(); b++) {
      Ball ball = balls.get(b);

      for (int bb = 0; bb < blockMaxCount; bb++) {

        if (!blockAlive[bb]) continue;

        int col = bb % blockColumns;
        int row = bb / blockColumns;

        int x = startBlockX + col * blockSpacingX;
        int y = startBlockY + row * blockSpacingY;

        // Collision detection
        if (
          ball.ballX + ball.radius > x &&
          ball.ballX - ball.radius < x + blockWidth &&
          ball.ballY + ball.radius > y &&
          ball.ballY - ball.radius < y + blockHeight
          ) {

          // Determine collision direction
          float deltaX = ball.ballX - (x + blockWidth / 2.0);
          float deltaY = ball.ballY - (y + blockHeight / 2.0);

          if (abs(deltaX) > abs(deltaY)) {
            ball.speedX *= -1;
          } else {
            ball.speedY *= -1;
          }

          // Destroy block
          blockAlive[bb] = false;
          blockCount--;
          score += blockPointsWorth;

          // Check special blocks
          for (int s = 0; s < specialBlocks.length; s++) {
            if (specialBlocks[s] == bb) {
              createBall(x + blockWidth / 2, y + blockHeight / 2);
              break;
            }
          }

          // Stop checking blocks for THIS ball
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

  // Game over screen handling inside draw()
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
}

class Ball {
  float ballX, ballY;
  float speedX, speedY;
  int radius = 25;
  boolean hitDebounce = false;

  Ball(float ballX, float ballY, float speedX, float speedY, int radius) {
    this.ballX = ballX;
    this.ballY = ballY;
    this.speedX = speedX;
    this.speedY = speedY;
    this.radius = radius;
    this.hitDebounce = hitDebounce;
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
  }

  void display() {
    fill(255);
    circle(ballX, ballY, radius);
  }
}