var ImageSize = [40, 40]; // [width, height]

var ObjectsMapping = {
  "L" : "closed-lift",
  "." : "earth",
  " " : "empty",
  "\\": "lambda",
  "/" : "lambda",
  "O" : "open-lift",
  "R" : "robot",
  "*" : "rock",
  "#" : "wall"
};

var ObjectNames = [];
for (var key in ObjectsMapping) {
  ObjectNames.push(ObjectsMapping[key]);
};

var Images = {};
for (var i = 0; i < ObjectNames.length; i++) {
  var img = document.createElement("img");
  img.src = "images/" + ObjectNames[i] + ".png";
  Images[ObjectNames[i]] = img;
};

var Cell = Class.create();
Object.extend(
  Cell.prototype = {
    initialize: function(x, y, cellType) {
      this.x = x;
      this.y = y;
      this.type = cellType;
      this.imageElem = Images[cellType];
      this.above = null;
      this.below = null;
      this.right = null;
      this.left = null;
      this.newState = null;
    },
    
    clearArroundCells: function() {
      this.above = null;
      this.below = null;
      this.right = null;
      this.left = null;
    },

    setArroundCells: function(map, x, y) {
      if (y < map.height) {
        this.above = map.getCell(x, y + 1);
      }
      if (y > 1) {
        this.below = map.getCell(x, y - 1);
      }
      if (x < map.width) {
        this.right = map.getCell(x + 1, y);
      }
      if (x > 1) {
        this.left = map.getCell(x - 1, y);
      }
    },

    calcNewState: function(remainedLambdaNum) {
      if (this.type == "rock") {
        this.calcNewStateForRock();
      }
      else if (this.type == "closed-lift") {
        this.calcNewStateForClosedList(remainedLambdaNum);
      }
      else {
      }
    },

    calcNewStateForRock: function() {
      if (this.below && this.below.type == "empty") {
        this.newState = "empty";
        this.below.newState = "rock";
      }
      else if (this.below       && this.below.type == "rock" &&
               this.right       && this.right.type == "empty" &&
               this.right.below && this.right.below.type == "empty") {
        this.newState = "empty";
        this.right.below.newState = "rock";
      }
      else if (this.below       && this.below.type       == "rock"         &&
               ( this.right       && this.right.type       != "empty" ||
                 this.right.below && this.right.below.type != "empty"    ) &&
               this.left        && this.left.type        == "empty"        &&
               this.left.below  && this.left.below.type  == "empty") {
        this.newState = "empty";
        this.left.below.newState = "rock";
      }
      else if (this.below       && this.below.type       == "lambda" &&
               this.right       && this.right.type       == "empty"  &&
               this.right.below && this.right.below.type == "empty") {
        this.newState = "empty";
        this.right.below.newState = "rock";
      }
    },

    calcNewStateForClosedList: function(remainedLambdaNum) {
      if (remainedLambdaNum == 0) {
        this.newState = "open-lift";
      }
    },

    update: function() {
      this.imageElem = Images[this.newState];
      this.type = this.newState;
      this.newState = null;
    },

    destroyRobot: function() {
      if (this.type == "rock" && this.below.type == "robot") {
        return true;
      }
      else {
        return false;
      }
    },

    // ここからRobot専用
    action: function(action) {
      if (this.type != "robot") {
        return;
      }
      switch (action) {
      case "L":
        this.moveLeft();
        break;
      case "R":
        this.moveRight();
        break;
      case "U":
        this.moveUp();
        break;
      case "D":
        this.moveDown();
        break;
      case "W":
        this.wait();
        break;
      case "A":
        this.abort();
        break;
      default:
      }
    },

    moveLeft: function() {
      if (this.movable(this.left)) {
        this.newState = "empty";
        this.left.newState = "robot";
      }
      else if (this.left && this.left.type == "rock" &&
               this.left.left.type == "empty") {
        this.newState = "empty";
        this.left.newState = "robot";
        this.left.left.newState = "rock";
      }
    },

    moveRight: function() {
      if (this.movable(this.right)) {
        this.newState = "empty";
        this.right.newState = "robot";
      }
      else if (this.right && this.right.type == "rock" &&
               this.right.right.type == "empty") {
        this.newState = "empty";
        this.right.newState = "robot";
        this.right.right.newState = "rock";
      }
    },

    moveUp: function() {
      if (this.movable(this.above)) {
        this.newState = "empty";
        this.above.newState = "robot";
      }
    },

    moveDown: function() {
      if (this.movable(this.below)) {
        this.newState = "empty";
        this.below.newState = "robot";
      }
    },

    movable: function(destCell) {
      if (destCell.type == "empty" ||
          destCell.type == "earth" ||
          destCell.type == "lambda" ||
          destCell.type == "open-lift") {
        return true;
      }
      else {
        return false;
      }
    },

    wait: function() {
    },

    abort: function() {
    }
  }
);

var Map = Class.create();
Object.extend(
  Map.prototype = {
    initialize: function(mapDataStr) {
      var mapConfig = this.parseMapDataString(mapDataStr);
      this.width = mapConfig.width;
      this.height = mapConfig.height;
      this.steps = 0;
      this.water = mapConfig.Water || 0;
      this.flooding = mapConfig.Flooding || 0;
      this.waterproof = mapConfig.Waterproof || 10;
      this.diving = 0;
      this.canvas = document.createElement("canvas");
      this.canvas.width = this.width * ImageSize[0];
      this.canvas.height = this.height * ImageSize[1];
      this.canvasCtx = this.canvas.getContext("2d");

      this.remainedLambdaNum = 0;
      this.cells = new Array(this.height);
      for(var i = 0; i < this.height; i++) {
        this.cells[i] = new Array(this.width);
        for(var j = 0; j < this.width; j++) {
          var cellType = mapConfig.eachCellTypes[i][j];
          this.cells[i][j] = new Cell( j + 1,
                                       this.height - i,
                                       cellType);
          if (cellType == "robot") {
            this.robot = this.cells[i][j];
          }
          if (cellType == "lambda") {
            this.remainedLambdaNum++;
          }
        }
      }

      this.won = null;
      this.lost = null;
      this.aborted = null;
    },
    
    parseMapDataString: function(dataStr) {
      var res = {};
      var dataStrAry =
        dataStr.split("\n").collect(
          function(e) {
            if (e.match(/(Water|Flooding|Waterproof) (\d+)/)) {
              res[RegExp.$1] = Number(RegExp.$2);
              return "";
            }
            return e.replace(/\r?\n$/, "");
          }
        ).filter(
          function(e) {
            return e.length > 0;
          }
        );

      res.height = dataStrAry.length;
      res.width = 0;
      for (var m = 0; m < dataStrAry.length; m++) {
        if (dataStrAry[m].length > res.width) {
          res.width = dataStrAry[m].length;
        }
      }
      res.eachCellTypes = new Array(res.height);
      for(var i = 0; i < res.height; i++) {
        res.eachCellTypes[res.height - (i + 1)] = new Array(res.width);
        for(var j = 0; j < res.width; j++) {
          var key = dataStrAry[res.height - (i + 1)][j] ?
            dataStrAry[res.height - (i + 1)][j] : " ";
          res.eachCellTypes[res.height - (i + 1)][j] = ObjectsMapping[key];
        }
      }
      return res;
    },

    setCanvas: function(id) {
      var screen = $(id); 
      screen.appendChild(this.canvas); 
    },

    getCell: function(x, y) {
      return this.cells[this.height - y][x - 1];
    },

    drawCells: function() {
      this.remainedLambdaNum = 0;
      for(var y = 1; y <= this.height; y++) {
        for(var x = 1; x <= this.width; x++) {
          var cell = this.getCell(x, y);
          if (cell.type == "lambda") {
            this.remainedLambdaNum++;
          }
          if (cell.newState) {
            if (cell.type == "open-lift" && cell.newState == "robot") {
              this.won = true;
            }
            cell.update();
            if (cell.destroyRobot()) {
              this.lost = true;
            }
            if (cell.type == "robot") {
              this.robot = cell;
            }
          }
          this.canvasCtx.drawImage(cell.imageElem,
                                   (cell.x - 1) * ImageSize[0],
                                   this.canvas.height - (cell.y * ImageSize[1]),
                                   ImageSize[0],
                                   ImageSize[1]
                                  );
          cell.clearArroundCells();
          cell.setArroundCells(this, x, y);
        }
      }
      this.drawWaterLevel();
    },

    drawWaterLevel: function() {
      this.canvasCtx.fillStyle = "rgba(40, 80, 200, 0.4)";
      this.canvasCtx.fillRect(0,
                              this.canvas.height - this.water * ImageSize[1],
                              this.canvas.width * ImageSize[0],
                              this.water * ImageSize[1]);
    },

    update: function() {
      for(var y = 1; y <= this.height; y++) {
        for(var x = 1; x <= this.width; x++) {
          var cell = this.getCell(x, y);
          cell.calcNewState(this.remainedLambdaNum);
        }
      }
      this.steps++;
      this.checkWeatherStatus();
    },

    checkWeatherStatus: function() {
      if (this.flooding && this.steps % this.flooding == 0) {
        this.water++;
      }
      if (this.robot.y <= this.water) {
        this.diving++; 
        if (this.diving > this.waterproof) {
          this.lost = true;
        }
      }
      else {
        this.diving = 0;
      }     
    },
 
    moveRobot: function(command) {
      if (command == "A") {
        this.aborted = true;
      }
      this.robot.action(command);
    }
  }
);

var World = Class.create();
Object.extend(
  World.prototype = {
    initialize: function() {
      this.map = null;
      this.mapDataString = MapData.sample1;
      this.robotCommandQueue = [];
      this.score = 0;
    },

    start: function() {
      this.map = new Map(this.mapDataString);
      this.map.setCanvas("screen");
      this.map.drawCells();
      this.displayMapWeatherStatus();
    },

    restart: function() {
      $("screen").removeChild(this.map.canvas);
      var mapDataStr = this.mapDataString;
      this.initialize();
      this.mapDataString = mapDataStr;
      this.displayCommands();
      this.map = new Map(this.mapDataString);
      this.map.setCanvas("screen");
      this.map.drawCells();
      this.displayMapWeatherStatus();
    },

    pushCommands: function(str) {
      var only_cmd_char = this.selectCommandCharacter(str);
      for (var i = 0; i < only_cmd_char.length; i++) {
        this.robotCommandQueue.push(only_cmd_char.charAt(i));
      }
      this.displayCommands();
    },

    selectCommandCharacter: function(str) {
      return str.replace(/[^WALRDU]*/gm, '');
    },

    displayInfo: function(){
      this.displayCommands();
      this.displayMapWeatherStatus();
    },

    displayMapWeatherStatus: function(){
      $("water").innerHTML = "Water:" + this.map.water;
      var floodCount = this.map.steps % this.map.flooding;
      floodCount = isNaN(floodCount) ? 0 : floodCount;
      $("flooding").innerHTML = "Flooding:" + this.map.flooding +
                                "/" + floodCount;
      $("waterproof").innerHTML = "Waterproof:" + this.map.waterproof +
                                  "/" + this.map.diving;
    },

    displayCommands: function(){
      if (this.robotCommandQueue.length >= 0) {
        $("registered-command").value = this.robotCommandQueue.join(",");
      }
    },

    step: function() {
      if (this.robotCommandQueue.length < 1) {
        alert("Robot のコマンドを登録してください");
        return;
      }
      // 1. Robot の行動
      this.map.moveRobot(this.robotCommandQueue.shift());
      this.map.drawCells();
      // 2. Map の更新
      this.map.update();
      this.map.drawCells();
      // 各種情報の表示
      this.displayInfo();
      // 3. 終了チェック
      this.checkWining();
      this.checkLosing();
      this.checkAborted();
    },
    
    checkWining: function() {
      if (this.map.won) {
        alert("You Win!");
      }
    },

    checkLosing: function() {
      if (this.map.lost) {
        alert("Robot was destroyed!");
      }
    },

    checkAborted: function() {
      if (this.map.aborted) {
        alert("Aborted!");
      }
    }
  }
);
