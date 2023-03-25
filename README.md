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


# Language Limitations

> ### Condition Rule

```js
//Valid
if (true) {}

  //Unvalid, a new pair of "(" expects a brand new conditional expression to be used, in hopes to change branch operators
if ((true)) {}
  //This is the kind of expression it expects
if ((true && false) || true) {}
```

```
