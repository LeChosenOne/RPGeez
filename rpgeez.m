#import <Foundation/Foundation.h>
#import "player.h"
#import "enemy.h"
#include <time.h>
#include <stdlib.h>

const char* Player_Classes[] = {"Warrior", "Mage", "Thief", "Paladin", "Wizard", "Assassin"};
const char* Player_Locations[] = {"Town", "Arena", "Grasslands", "Desert", "Forest", "Mountains"};
const char* Player_Abilities[] = {"None", "Slash", "Herotime", "Haymaker", "Heal", "Fireball", "Lifesteal", "Boom", "ManaGain", "Stab", "Misdirect", "Steal", "Assassinate"};
typedef enum {Town, Arena, Grasslands, Desert, Forest, Mountains} location_codes;
typedef enum {Common_Lynx, Sand_Elemental, Rock_Golem, Wood_Elf, Ent, Griffin, Phoenix} monster_codes;
typedef enum {None, Slash, Herotime, Haymaker, Heal, Fireball, Lifesteal, Boom, ManaGain, Stab, Misdirect, Steal, Assassinate} ability_codes;
const int player_manaCosts[] = {0, 0, 0, 0, 5, 0, 5, 13, 0, 0, 0, 0, 0};
const int casts[] = {0, 1000, 2, 2, 2, 1000, 4, 6, 2, 1000, 2, 2, 1};
int main (int argc, const char * argv[]){
      srand(time(NULL)); //setup randomness seed
      NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      //set up initial game variables
      char name[20];
      char class_name[10];

      //get name and class
      puts("What name will you be known as?");
      fgets(name,20,stdin);
      puts("What is your profession? (warrior = 0, mage = 1, thief = 2)");
      fgets(class_name, 10, stdin);
      int class = atoi(class_name);
      //keep going until user requests a usable class
      while (class < 0 || class > 2){
        puts("I didn't understand that... What is your profession? (warrior = 0, mage = 1, thief = 2)");
        fgets(class_name, 10, stdin);
        class = atoi(class_name);
      }
      //build player object
      strtok(name, "\n");
      NSString * player_name = [NSString stringWithUTF8String:name];
      Player * pl = [Player PlayerWithName:player_name andClass: class];
      [pl setLocation:Town];

      printf("\nWelcome %s the %s to RPGeez.\n", [[pl name] UTF8String], Player_Classes[[pl class]]);
      printf("::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::\n\n");
      printf("Type \"help\" for a list of available actions.\n\n");

      //main game loop
      short in_battle = 0;
      Enemy * enemy;
      while ([pl health] > 0 && [pl medals] < 10){
        while(in_battle){
          //gain 1 mana per turn in battle
          if(pl.mana < pl.max_mana){
            pl.mana++;
          }
          //print stats
          printf("\n----------------------------------------\n");
          printf("|Your Stats\t%s's Stats\n",[[enemy name] UTF8String]);
          printf("|---------\t-----------\n");
          printf("|HP %d/%d\tHP %d/%d\n",[pl health],[pl max_hp],[enemy health],[enemy max_hp]);
          printf("|MP %d/%d\n", [pl mana],[pl max_mana]);
          printf("|STR:%d  \tSTR:%d \n", [pl strength], [enemy strength]);
          printf("|INT:%d  \tINT:%d \n", [pl intelligence], [enemy intelligence]);
          printf("|SPD:%d  \tSPD:%d \n", [pl speed], [enemy speed]);
          printf("----------------------------------------\n\n");

          //ask for user attack
          int attack = -1;
          while(attack != [[pl.abilities objectAtIndex: 0] intValue] && attack != [[pl.abilities objectAtIndex: 1] intValue] && attack != [[pl.abilities objectAtIndex: 2] intValue] && attack != [[pl.abilities objectAtIndex: 3] intValue]){
            printf("Valid abilities: \n");
            int i = 0;
            for(NSNumber * ability in pl.abilities){
              if([ability intValue] != None){
                printf("\t %s (%d MP) = type \"%d\" to use... \n", Player_Abilities[[ability intValue]], player_manaCosts[[ability intValue]], i);
              }
              i++;
            }
            printf("> ");
            int choice = -1;
            scanf("%d", &choice);
            getchar(); //grab the trailing newline from stdin... its weird i know
            if (choice >= 0 && choice <= 3){
              if ([[pl.abilities objectAtIndex: choice] intValue] != None){
                attack = [[pl.abilities objectAtIndex: choice] intValue];
                if (player_manaCosts[attack] > pl.mana){
                  attack = -1;
                  printf("You don't have the mana for that!\n");
                }

              }
            }
          }

          //determine who can attack based on speed
          int attacker = rand() % (enemy.speed + pl.speed);
          if(attacker < pl.speed){
            //attack with chosen ability
            int damage = [pl attackWithAbility:attack atEnemy:enemy];
            if(damage == 0){
              printf("Did no damage to %s...\n", [enemy.name UTF8String]);
            }
            else{
              printf("\nHit %s for %d!\n", [enemy.name UTF8String], damage);
            }
            [enemy damage:damage];
          }
          else{
            int damage = [enemy attack];
            [pl damage:damage];
            printf("You were hit for %d!\n", damage);
          }
          if(pl.health <= 0){
            printf("You are dead.\n");
            in_battle = 0;
            exit(0);
          }
          if(enemy.health <= 0){
            int gold = enemy.value + rand() % 5;
            int xp = enemy.value + rand() % 10;
            printf("Defeated %s. Gained %d xp and %d gold.\n\n", [enemy.name UTF8String], xp, gold);
            [pl awardXP: xp];
            [pl resetStats];
            in_battle = 0;
            pl.gold += gold;
            [enemy release];
            continue;
          }
        }

        printf("\n\n");
        printf("You are currently in the %s...\n", (char *)Player_Locations[pl.location]);
        printf("What do you want to do?\n> ");
        char action[2000];
        fgets(action, 2000, stdin);
        char delim[] = " ";
        char * nextWord = strtok(action, delim);
        char lastLetter = nextWord[strlen(nextWord) - 1];
        if(lastLetter == 10){
          nextWord[strlen(nextWord) - 1] = 0;
        }
        printf("\n\n");

        if (strcmp(nextWord, "help") == 0){
          printf("\n\nValid actions:\n");
          printf("\t go north/east/south/west\n");
          printf("\t search (shortcut: s)\n");
          printf("\t abilities\n");
          printf("\t status\n");
          printf("Only valid in town:\n");
          printf("\t buy\n");
          printf("\t inn\n");
          printf("\t arena\n");
          printf("Only valid in the arena:\n");
          printf("\t challenge\n");
          printf("\t bet\n");
        }
        else if (strcmp(nextWord, "go") == 0){
          char * dir = strtok(NULL, delim);
          char * direction = strtok(dir, "\n"); //remove trailing newline from input
          //                Grasslands = 2
          //
          // Mountains = 5   Town = 0 (Arena=1)     Desert = 3
          //
          //                  Forest = 4
          switch (pl.location){
            case Town:
              if (strcmp(direction, "north") == 0){
                [pl setLocation:Grasslands];
              }
              if (strcmp(direction, "east") == 0){
                [pl setLocation:Desert];
              }
              if (strcmp(direction, "south") == 0){
                [pl setLocation:Forest];
              }
              if (strcmp(direction, "west") == 0){
                [pl setLocation:Mountains];
              }
              break;
            case Arena:
              [pl setLocation:Town];
              break;
            case Desert:
              if (strcmp(direction, "north") == 0){
                [pl setLocation:Grasslands];
              }
              if (strcmp(direction, "east") == 0){
                printf("There's a raging sandstorm, better go in a different direction...");
              }
              if (strcmp(direction, "south") == 0){
                [pl setLocation:Forest];
              }
              if (strcmp(direction, "west") == 0){
                [pl setLocation:Town];
              }
              break;
            case Grasslands:
              if (strcmp(direction, "north") == 0){
                printf("There's only tundra and ice up north, better go in a different direction...");
              }
              if (strcmp(direction, "east") == 0){
                [pl setLocation:Desert];
              }
              if (strcmp(direction, "south") == 0){
                [pl setLocation:Town];
              }
              if (strcmp(direction, "west") == 0){
                [pl setLocation:Mountains];
              }
              break;
            case Mountains:
              if (strcmp(direction, "north") == 0){
                [pl setLocation:Grasslands];
              }
              if (strcmp(direction, "east") == 0){
                [pl setLocation:Desert];
              }
              if (strcmp(direction, "south") == 0){
                [pl setLocation:Town];
              }
              if (strcmp(direction, "west") == 0){
                printf("The mountains get too steep if you go any further, better go in a different direction...");
              }
              break;
            case Forest:
              if (strcmp(direction, "north") == 0){
                [pl setLocation:Town];
              }
              if (strcmp(direction, "east") == 0){
                [pl setLocation:Desert];
              }
              if (strcmp(direction, "south") == 0){
                printf("The forest is uncharted this far south, better go in a different direction...");
              }
              if (strcmp(direction, "west") == 0){
                [pl setLocation:Mountains];
              }
              break;
            default:
              break;
          }
        }
        else if (strcmp(nextWord, "search") == 0 || strcmp(nextWord, "s") == 0){
          int found_monster = 0;
          switch(pl.location){
            case Town:
              printf("There are no monsters to search for in the town...\n");
              break;
            case Arena:
              printf("There are no monsters to search for in the arena...\n");
              break;
            case Grasslands:
              found_monster = rand() % 100;
              if(found_monster > 40){
                in_battle = 1;
                enemy = [Enemy EnemyWithType:Common_Lynx];
                printf("Common Lynx encountered!\n");
              }
              else{
                printf("Didn't find much...\n");
              }
              break;
            case Desert:
              found_monster = rand() % 100;
              if(found_monster > 40){
                if(found_monster < 60){
                  enemy = [Enemy EnemyWithType:Rock_Golem];
                  printf("Rock Golem encountered!\n");
                }
                else{
                  enemy = [Enemy EnemyWithType:Sand_Elemental];
                  printf("Sand Elemental encountered!\n");
                }
                in_battle = 1;
              }
              else{
                printf("Didn't find much...\n");
              }
              break;
            case Forest:
              found_monster = rand() % 100;
              if(found_monster > 40){
                if(found_monster < 60){
                  enemy = [Enemy EnemyWithType:Ent];
                  printf("Ent encountered!\n");
                }
                else{
                  enemy = [Enemy EnemyWithType:Wood_Elf];
                  printf("Wood Elf encountered!\n");
                }
                in_battle = 1;
              }
              else{
                printf("Didn't find much...\n");
              }
              break;
            case Mountains:
              found_monster = rand() % 100;
              if(found_monster > 40){
                if(found_monster < 60){
                  enemy = [Enemy EnemyWithType:Griffin];
                  printf("Griffin encountered!\n");
                }
                else{
                  enemy = [Enemy EnemyWithType:Phoenix];
                  printf("Phoenix encountered!\n");
                }
              }
              else{
                printf("Didn't find much...\n");
              }
              in_battle = 1;
              break;
            default:
              break;
          }
        }
        else if (strcmp(nextWord, "status") == 0){
          [pl printStatus];
        }
        else if (strcmp(nextWord, "inn") == 0){
          if(pl.location != Town){
            printf("There's no inn here! Better go back to the nearest town.\n");
            continue;
          }
          printf("The room's mostly held together with stains but its got a warm bed.\nCosts 100 gold.\ntype \"y\" or \"n\"\n> ");
          if(pl.gold < 100){
            printf("Sorry, try the streets friend... (not enough gold)\n");
            continue;
          }
          int dumb_new_line_that_i_have_to_get_first;
          scanf("%d", dumb_new_line_that_i_have_to_get_first);
          char decision = getchar();
          if(decision == 'y'){
            pl.gold -= 100;
            pl.health = pl.max_hp;
            printf("\n*Fully Rested*\n\n");
          }
          scanf("%d", dumb_new_line_that_i_have_to_get_first);
        }
      }
      [player_name release];
      [pl release];
      [pool release];
      return 0;
}
