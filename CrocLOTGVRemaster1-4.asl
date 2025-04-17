
state("Croc64", "1.0/1.1")
{
  int firstLevelComplete : 0xAEF74E; // SaveBuf.LevelData[ 1]
  int danteComplete : 0xAEF79C;      // SaveBuf.LevelData[79]
  int gameState : 0xAF45D8;          // CurrentGameState
  int nextGameState : 0xA48E24;      // NextGameState
  int isLoading : 0xAF45DC;          // speedrun.is_loading;
  int currentLevel : 0xAF1F58;       // level_number_order
  int currentRoom : 0xAF1F54;        // sublevel_number
}

state("Croc64", "1.4")
{
  int firstLevelComplete : 0xAF0A4E; // SaveBuf.LevelData[ 1]
  int danteComplete : 0xAF0A9C;      // SaveBuf.LevelData[79]
  int gameState : 0xAF58D8;          // CurrentGameState
  int nextGameState : 0xA49E2C;      // NextGameState
  int isLoading : 0xAF58DC;          // speedrun.is_loading;
  int currentLevel : 0xAF3258;       // level_number_order
  int currentRoom : 0xAF3254;        // sublevel_number
}

init
{
  print("croc.exe: 0x" + modules.First().ModuleMemorySize.ToString("X"));
  var firstModule = modules.First();
  switch (firstModule.ModuleMemorySize)
  {
    case 0xB73000:
      version = "1.0/1.1";
      break;
    case 0xB74000:
      version = "1.4";
      break;
    default:
      return;
  }
}

startup
{
  settings.Add("Split_Room", false, "Split On Room");
  settings.Add("Split_Level", true, "Split On Level");
  settings.Add("Split_Boss", false, "Split On Boss/Half World");

  // Indexes of the levels AFTER a boss (in any%) or a jigsaw (in 100%)
  vars.halfWorld = new int[] {
    5, 10, 15, 20, 25, 30, 35, 40, 50
  };

  // Keeping track of highest visited level to prevent splitting again if the player backtracks a level
  vars.highestLevel = 0;
  // Keeping track of if we have beated Dante to prevent double splits
  vars.anyCompleted = false;
}

start
{
  // MainMenu = 3
  // Transitioning = 11
  // Level Not complete = 0
  // Level Complete = 128
  if (current.gameState == 11 && old.gameState == 3 && current.firstLevelComplete == 0)
  {
    return true;
  }
}

onStart
{
  vars.highestLevel = 0;
  vars.anyCompleted = false;
}

split
{
  // Bit of code duplication to correctly handle users enabling both level and boss splitting

  if (settings["Split_Room"])
  {

    if(current.currentRoom != old.currentRoom)
    {
      return true;
    }

  }

  if (settings["Split_Level"])
  {

    if (current.currentLevel > old.currentLevel && current.currentLevel > vars.highestLevel)
    {
      if (current.danteComplete == 128)
      {
        vars.anyCompleted = true;
      }
      vars.highestLevel = current.currentLevel;
      return true;
    }

  }

  if (settings["Split_Boss"])
  {
    if(current.currentLevel > old.currentLevel && current.currentLevel > vars.highestLevel)
    {
      if (Array.IndexOf(vars.halfWorld, current.currentLevel) != -1)
      {
        if (current.danteComplete == 128)
        {
          vars.anyCompleted = true;
        }
        vars.highestLevel = current.currentLevel;
        return true;
      }
     
    }
  }

  // Beating Dante in any% doesnt increment the level counter
  // Listen for the first room change (starting the credits) after Dante gets marked as beaten
  if (current.currentRoom != old.currentRoom && current.danteComplete == 128 && vars.anyCompleted == false)
  {
    vars.anyCompleted = true;
    return true;
  }

}

isLoading
{
  return (
    current.isLoading != 0 ||
    (current.nextGameState != 12 && current.gameState != current.nextGameState) ||
    current.gameState == 11
  );
}
