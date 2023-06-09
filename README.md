# RUX
RUX (Robustly Unstable Xylophone) is a hobby project with a funny name. It's a programming language created on roblox.
https://www.roblox.com/games/12769067560/Rux


# Language Basics
These are some basics about the RUX language so far

> ### Creating Variables

```js

let name = "Max";
let age = 21;

```


> ### Referencing Variables

```js

let number1 = 20;
let number2 = 50;

let result = ($number1 + $number2) * 2;   //Result is 140

```

> ### Concatinating Strings

```js

let first_name = "Max";
let last_name = "Michael";

let greeting = "Welcome";

let result = $greeting + ", " + $first_name + " " + $last_name + "!"; //Welcome, Max Michael!

```

> ### If Statements

```js

let name = "Michael"; let age = 15;

if ($age > 18 || $name == "Michael") {
  let message = "Correct!";
} else if ($age == 15 && $name == "Michael") {
  let message = "Found me!";
} else {
  let message = "Incorrect!";
}

```

> ### Functions

```js

let divide := (x, y) {
  let result = 0;
  
  if ($y == 0) {
    $result = "Error, cannot divide by 0";
  } else {
    $result = $x / $y;
  }
  
  $log($result);
}

$divide(1, 0);  //Cannot Divide by 0

```

> ### Loops

```js

for (let i = 20; $i < 100; $i = $i + 1) {
  $log($i);
}

let x = 0;
while ($x != 100) {
  $x = $x + 1;
  $log($x);
}

```

> ### Arrays

```js

let array = ["A", "B", "C", [5, 6, 7]];
$log($array[1]);    //A

$log($array[3][2]); //6

$array[3] = [1, 2, 3];
$array[2] = $array[2] + "ACK";  //BACK

```

> ### Compound Operators

```js

let num = 10;

$num += 1; $log($num);    //11

```

# Globals

> ### LOG

```js
//Outputs the message given into the output

$log("Hello");
```

> ### SLEEP

```js
//Pauses Execution for the amount of time given within parentheses

$sleep(0.5);
$log("After 0.5 Seconds!");
```

> ### RANDOM

```js
//Gives the variable given as first argument a random value between two limits

let rand = 0;
$random($rand, 1, 100);
$log($rand);
```

# Limitations

> ### Little bugs might occur with arrays for now, fix in later versions
