# Forever Casino — WoW Forever addon

## Latest release: v1.6.0

**[Download ForeverCasino v1.6.0 ZIP](https://raw.githubusercontent.com/ChillxHunter/ForeverCasino/main/ForeverCasino_v1.6.0_Coin_Flip_Target.zip)**

Coin Toss and Deathroll for solo practice and two-player games. WoW Forever interface 16001. This addon is recreational and does not provide payments, prizes, stakes or transfers.

### New in 1.6.0
- Two genuine-looking coin faces, Heads and Tails, included as WoW-compatible textures
- A coin-flipping animation that turns edge-on, then reveals the result in a large popup
- **YOUR TARGET: HEADS/TAILS** above the coin; pick the target before a match
- For multiplayer Coin Toss, the challenger selects a side and the other player receives the opposite
- Solo Coin Toss results and the saved win/loss scoreboard respect the selected target
- Keeps Deathroll, round minimap icon, 18+ self-confirmation and delayed addon chat announcements

### Install
1. Download the latest ZIP above, not the GitHub source repository ZIP.
2. Remove the old `ForeverCasino` folder.
3. Extract the ZIP and place its `ForeverCasino` folder in `World of Warcraft/_forever_/Interface/AddOns/`.
4. Restart the game and type `/casino`.

**Both players need v1.6.0** for challenges. Results come from a local pseudorandom generator rather than a server-verified roll; don't use them for valuable outcomes.

Lua syntax and simulated match tests passed, but game-client integration still requires testing.

SHA-256 of v1.6.0 ZIP: `c88a8f1d25f83dbae13737e84e64ce4d237e8cc3b45dbbae30f827d51f6ae326`
