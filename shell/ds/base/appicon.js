.pragma library

// AppIcon's state shared by every instance for the shell's whole run (spec 007): the missing
// shader is reported once, not once per icon nor per opening of the menu.
var warned = false;

// True only the first time it is called.
function firstWarning() {
    if (warned)
        return false;
    warned = true;
    return true;
}
