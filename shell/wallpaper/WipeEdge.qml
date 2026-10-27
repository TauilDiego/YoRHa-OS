import QtQuick
import "../ds/primitives"

// The wipe's moving edge (spec 004, research R5): the game's dotted rule turned upright, its line
// on the edge and its ticks and ∵ trios trailing on the new picture's side, as in the approved
// mockup. `x` is the edge; the rule spans `length` (the screen's height).
Rule {
    id: root

    property real length: 0

    kind: "dotted"
    width: length
    transformOrigin: Item.TopLeft
    rotation: 90                 // local x runs down, the pattern hangs to the left
}
