# playball-relay

A relay override for the [Baseball Diamond](https://wiki.kingdomofloathing.com/Baseball_Diamond)'s
[Play Ball!](https://wiki.kingdomofloathing.com/Play_Ball!) choice, which rearranges the page
and shows what each pitch is worth.

## Installation

```
git checkout ivanlei/playball-relay
```

KoLmafia installs [Ezandora's Choice-Override](https://github.com/Ezandora/Choice-Override)
alongside it (see `dependencies.txt`), which is the library that lets several scripts decorate
choice adventures without colliding.

Turn on KoLmafia's own choice spoilers to get the effect notes under each button:

```
set relayShowSpoilers=true
```

## Examples

A major pitch on offer: both minor pitches of that element have been thrown, so the Schenectady
Scorcher is up, marked `●● → gets an out`. The lineup box has moved to the left, away from the
batter.

![A major pitch on offer](/playball_relay01.png)

After throwing it: the batter shows the pitch they got, KoL marks the out with an X, and hot now
reads `✓ Schenectady Scorcher thrown`, since an element's major is only offered once an inning.

![After throwing a major pitch](/playball_relay02.png)

## What it changes

- **Pitches move into the lineup box**, under the list of batters, instead of sitting near the
  bottom of the field where the last of them spills outside the frame.
- **Each pitch is coloured by its element**, using the wiki's colours, along with KoLmafia's
  own effect note (trimmed of the repeated "to Baseball Diamond enchants").
- **Each pitch shows how close its element is to its major pitch** - `●○ → Ice Them Out` - since
  an element's major is only offered once you've thrown both of its minor pitches. A major on
  offer reads `●● → gets an out`, and a spent element reads `✓ Ice Them Out thrown`.
- **Every batter you've pitched to shows the pitch they got**, in that pitch's colour. The page
  itself never says this, so the script records the pitches on offer each time and matches them
  to the option you submit.
- **The lineup box keeps out of the batter's way**, moving to whichever side of the field the
  batter isn't on, and centring once the inning is over.
- **The stadium is trimmed** to end below the lineup box rather than running on for the empty
  outfield, KoL's result text moves below the field instead of overlapping the lineup, and the
  batter is hidden once the inning is over.

## Notes

- Two preferences hold the inning's state, `_pbOffered` and `_pbThrown`. Both start with `_`, so
  KoLmafia clears them at rollover, and a fresh inning resets them.
- A pitch thrown while the script isn't installed can't be recovered: the page only sends back an
  option number, whose meaning depends on the buttons that were on offer at the time.

## Testing

`testdata/` holds two pages saved from the relay browser, before any pitch and after the first,
with the session password hash replaced by a placeholder. They're what the script was developed
against, and are handy for checking a change without waiting for an inning.
