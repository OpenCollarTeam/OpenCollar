## Coding Style Guide

### Common recommendations
Please, keep source code well-formatted and easy to read!

Use understantable, but not too complicated names.
Use `TRUE` and `FALSE` for boolean purposes.
Use predefined constants instead of "magic numbers" (for example, `llAttachToAvatar(ATTACH_NECK);` instead of `llAttachToAvatar(39);`).
Split different code blocks or steps with spaces.
Do not make unnecessary complexity.
Avoid of uncommon hacks (for example, use `llGetListLength(lMyList)` instead of `(lMyList != [])`).
Avoid of unnecessary memory savings, like loop variables in global scope.
Feed unicorns, not fire dragons.

### Indentation
Use spaces, not tabs. Indent size is 4 spaces.

Right:
```
integer MyFunc() {
    llOwnerSay("test");
}
```
Wrong:
```
integer MyFunc() {
  llOwnerSay("test");
}
```

### Names
Use CamelCase. Capitalize first letter.
Abbreviation must be upper-cased (example: `RLV`, `LL`).

Variable names must have prefix that shows variable type:
 - `i` - integer;
 - `b` - boolean (integer variable that is being used as boolean, with `TRUE` or `FALSE` values only);
 - `s` - string;
 - `k` - key;
 - `v` - vector;
 - `r` - rotation or quaternion;
 - `l` - list.

Global variables (defined outside of functions or state events) must have prefix `g_`, then type prefix.

Exception: loop variables like `i`, `j`, `k`.

Constants must be written in upper-case, without any prefixes, with underscore character (`_`) as word delimiter.

Right:
```
integer MY_CONSTANT = 10;

integer g_iMyInt;
integer g_bMyBool;
string g_sMyStr;

string MyFunc(list lParams) {
}
```
Wrong:
```
integer MyConstant = 10;

integer my_int;
integer myBool;
string MyStr;

string my_Func(list params) {
}
```

### Braces
Place the open brace on the line preceding the code block.
Place the close brace on its own line.
`else` statement must be placed on same line with preceding close brace of `if` block.
`while` statement must be placed on same line with preceding close brace of `do` block.

Right:
```
MyFunc(integer iParam) {
    if (iParam == 1) {
        llOwnerSay("Heads");
    } else {
        llOwnerSay("Tails");
    }
    
    integer i;
    for (i = 4 * iParam; i > 0; i--) {
        llOwnerSay((string)i);
    }
}
```
Wrong:
```
MyFunc(integer iParam)
{
    if (iParam == 1) {
        llOwnerSay("Heads");
    }
    else {
        llOwnerSay("Tails");
    }
    
    integer i;    
    for (i = 4 * iParam; i > 0; i--) { llOwnerSay((string)i); }
}
```

### Statements
Always use braces with `if`/`else`, `for`, `while`, `do` statements, even with single-line blocks.
Exception: a lot of short `if` statements with similar content.
Unwelcome exception: short `if` statements.

Right:
```
if (g_bMyBool) {
    llOwnerSay("True");
    g_bMyBool = FALSE;
} else {
    llOwnerSay("False");
}
```
Wrong:
```
if (g_bMyBool) {
    llOwnerSay("True");
    g_bMyBool = FALSE;
} else llOwnerSay("False");
```
Exception (lot of `if` statements):
```
if (sName == "test1") g_iTest1 = (integer)sValue;
else if (sName == "test2") g_iTest2 = (integer)sValue;
else if (sName == "test3") g_iTest3 = (integer)sValue;
else if (sName == "test4") g_iTest4 = (integer)sValue;
else if (sName == "test5") g_iTest5 = (integer)sValue;
```
Unwelcome exception (short `if` statement):
```
if (g_bOn) lButtons += "OFF";
else lButtons += "ON";
```

### Operators and punctuation
Write unary operators together with their expressions.
Use spaces between binary operator arguments.
Use spaces before and after statement keywords like `if`.
Use spaces after comma (`,`) in arguments lists.
Use spaces after semicolon (`;`) in expressions.

Right:
```
for (i = 0; i < 10; i++) {
    llSay(-10, (string)i);
}
```
Wrong:
```
for(i=0; i<10;i++) {
    llSay(-10,(string)i);
}
```

### Miscellaneous
If function accepts list arguments (like `llSetLinkPrimitiveParamsFast` or `llHTTPRequest`), please write each slice of arguments on single line.

Right:
```
llSetLinkPrimitiveParamsFast(LINK_SET, [
    PRIM_FULLBRIGHT, ALL_SIDES, FALSE,
    PRIM_LINK_TARGET, llDetectedLinkNumber(0),
    PRIM_FULLBRIGHT, ALL_SIDES, TRUE
]);
```
Wrong:
```
llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_FULLBRIGHT, ALL_SIDES, FALSE, PRIM_LINK_TARGET, llDetectedLinkNumber(0), PRIM_FULLBRIGHT, ALL_SIDES, TRUE]);
```

