# relative_imports
![Build](https://github.com/instance-id/relative_imports/workflows/Build/badge.svg) [![Actions Panel](https://img.shields.io/badge/actionspanel-enabled-brightgreen)](https://www.actionspanel.app/app/instance-id/relative_imports)

---
[ IntelliJ](#setup) | [VSCode](#configuration-for-vscode) | [CLI](#example-usage-via-command-line) | [Arguments](#arguments) |  


An IDE agnostic tool to automatically convert your Flutter/Dart projects self-package (package:myproject) imports to relative imports (../myfiles.dart).   

If your IDE can perform "on-save" actions, macros, or hotkey triggered commands to the terminal with arguments, you should be able to automate on save, just as you would with dartfmt.  


If, when your IDE automatically adds imports to your local project files, they are brought in as package imports like this:
```dart
import 'package:relative_imports/file1.dart';
import 'package:relative_imports/folder1/file2.dart';
import 'package:relative_imports/folder2/file3.dart';
```
They will be converted to the proper local relative imports like this:
```dart
import 'file1.dart';
import 'folder1/file2.dart';
import '../folder2/file3.dart';
```

---

## Setup:  
### **<a name="setup-intellij">Configuration for IntelliJ or Android Studio:</a>**
Press ```ctrl+alt+s``` to bring up the settings menu.
Since it can be located in different menus between IDE's, type "external tools", and then select it in the menu below.

![](https://i.imgur.com/0HY4fTO.png)

Press the ```+``` button to add a new external tool.

![](https://i.imgur.com/0cZsk5w.png)


Fill out the fields as seen below, making any adjustments necessary for your local system in the "Program" field.  
(The '-y' flag is optional. When present, changes are automatically applied when the tool is ran)

![](https://i.imgur.com/gWsWoYI.png)

Finally, you can assign a hotkey to the new tool.  

Within the previously used settings menu, locate the Keymap section, and in the eight pane, locate the "Tools" top level menu item, followed by "External Tools" submenu. There you should find the newly created tool. Double or right click on it to be able to assign a new hotkey. 

![](https://i.imgur.com/jFqFvI0.png)

Once these steps have been completed, you should be able to now, upon having a .dart file open and focused, hit the hotkey and if there are any imports present that are elidgable to convertion to relative imports, they will be.

---

## **Configuration for VSCode**

Either press ```ctrl+alt+shift+s ``` to bring up the "Configure Tasks" menu
or go to the Terminal menu and select it.

![](https://i.imgur.com/nV5kYUB.png)

Select "Create task.json file from template"  
![](https://i.imgur.com/1xoytR1.png)

Select "Others Example to run from arbitrary external command"  
![](https://i.imgur.com/J6VwEmT.png)

In the newly created task.json file, paste the configuration below, and then make any adjustments necessary to match your local environment or preferences.

```json5
{
    // See https://go.microsoft.com/fwlink/?LinkId=733558
    // for the documentation about the tasks.json format
    "version": "2.0.0",
    "tasks": [
        {
            "label": "flutter_relative_imports",
            "type": "shell",
            "windows": {
                "command": "C:\\files\\relative_imports.exe",
            },
            "linux": {
                "command": "relative_imports",
            },
            "osx": {
                "command": "relative_imports",
            },
            "args": [
                "-p", "${workspaceFolder}",
                "-f", "${fileBasename}",
                "-y"
            ],
            "options": {
                "cwd": "${workspaceFolder}/lib"
            },
            "presentation": {
                "reveal": "silent",
                "panel": "shared"
            },
        }
    ]
}
```

Lastly, you can now trigger the task as you wish, such as creating a new keybind. Below is an example keybind for this new task.

```json
    {
        "key": "ctrl+alt+;",
        "command": "workbench.action.tasks.runTask",
        "args": "flutter_relative_imports"
    }
```

## Example usage via command line
```
C:\tools\relative_imports.exe -p C:\projects\my_project\pubspec.yaml -f C:\projects\my_project\lib\myfile.dart -y
```

---
## Arguments:  
```
 file-name        (-f)  The path the .dart file in which to convert imports to relative
 directory-path   (-d) 1) Project root directory (1 or 2 Required)
 pubspec-location (-p) 2) The path to your projects pubspec.yaml (1 or 2 Required)
 auto-apply       (-y) If -y argument is set, automatically apply all import changes. Otherwise you will be prompted to confirm the changes        
 verbose          (-v) If -v argument is set, additional log messages will be shown
```

---
### Notes:  
To help with cross-platform compatibility, as there was issue on Windows trying to utilize the absolute path of the 
intended target file in which the imports were to be converted, glob is used for filename matching.

Doing it this way has been working well, but I am not sure if it will become an issue for very large projects 
with hundreds/thousands of files. If so, I will go about it a different way and make sure the direct path to the 
intended target file is used, instead of matching by filename.

I will also be doing some "best-practice" refactoring.


![alt text](https://i.imgur.com/cg5ow2M.png "instance.id")