function setup() {
  createCanvas(400, 400);
  example();
}

function draw() {
  
}

function example() {
  background(220);
  const point1 = [200, 100];
  const point2 = [200, 300];
  const point3 = [100, 200 + (Math.random() - 0.5) * 350];
  const point4 = [300, 200 + (Math.random() - 0.5) * 350];
  
  const int_point = intersect_point(point1[0],point1[1], point2[0],point2[1], point3[0],point3[1], point4[0],point4[1]);
  
  stroke(0);
  strokeWeight(3);
  line(point1[0], point1[1], point2[0], point2[1]);
  line(point3[0], point3[1], point4[0], point4[1]);
  noStroke();
  if(int_point == false) return
  fill(255, 0, 0);
  ellipseMode(RADIUS);
  ellipse(int_point[0], int_point[1], 5);
}


function intersect_point(x1, y1, x2, y2, x3, y3, x4, y4) {

  // Check if none of the lines are of length 0
	if ((x1 === x2 && y1 === y2) || (x3 === x4 && y3 === y4)) {
		return false
	}

	denominator = ((y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1))

  // Lines are parallel
	if (denominator === 0) {
		return false
	}

	let ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denominator
	let ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denominator

  // is the intersection along the segments
	if (ua < 0 || ua > 1 || ub < 0 || ub > 1) {
		return false
	}

  // Return a object with the x and y coordinates of the intersection
	let x = x1 + ua * (x2 - x1)
	let y = y1 + ua * (y2 - y1)

	return [x, y]
}


function keyPressed() {
  if (key == 'r') {
    example();
  }
}