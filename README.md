# relative_imports

An IDE agnostic tool to automatically convert your projects dart/flutter imports to relative imports.   

If your IDE can perform "on-save" actions, macros, or hotkey triggered commands to the terminal with arguments, you should be able to automate on save, just as you would with dartfmt.  

 
Your import may go from something like this:
```dart
import 'package:dart_relative_imports/file1.dart';
import 'package:dart_relative_imports/folder1/file2.dart';
import 'package:dart_relative_imports/folder2/file3.dart';
 ```
to something like this:
```dart
import 'file1.dart';
import 'folder1/file2.dart';
import '../folder2/file3.dart';
 ```
### Examples:  
Configuration for IntelliJ or Android Studio:

![](.repo_images/szZSQzf.png)

Example usage via command line:
```
C:\tools\relative_imports.exe -p C:\projects\my_project\pubspec.yaml -f myfilename -y
```

### Arguments:  
```
 file-name        (-f)  The name of the .dart file in which to convert imports to relative (do not include extension)
 directory-path   (-d) 1) Project root directory (1 or 2 Required)
 pubspec-location (-p) 2) The path to your projects pubspec.yaml (1 or 2 Required)
 auto-apply       (-y) If -y argument is set, automatically apply all import changes. Otherwise you will be prompted to confirm the changes        
 verbose          (-v) If -v argument is set, additional log messages will be shown
```

#### Notes:  
To help with cross-platform compatibility glob was used for file matching and there was issue on Windows trying to pass the absolute path of the intended target file in which the imports were to be converted. Due to this, just the filename without the .dart extension is passed in using the projectroot/lib folder as the working directory. It has been working well doing it this way, but I am not sure if it will become an issue with very projects. If so, I will go about it a different way and make sure that the direct path to the intended target file is used instead of matching by filename.

![alt text](https://i.imgur.com/cg5ow2M.png "instance.id")